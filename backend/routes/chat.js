const express = require('express');
const router = express.Router();
const Chat = require('../models/chatModel');
const User = require('../models/user');
const multer = require('multer');
const { uploadImage } = require('../utils/cloudinary');

// Configurar multer para recibir imágenes
const storage = multer.memoryStorage();
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10 MB máximo
    },
    fileFilter: (req, file, cb) => {
        // Solo aceptar imágenes
        console.log('Multer fileFilter - mimetype:', file.mimetype);
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(null, false); // Rechazar pero no lanzar error
        }
    }
});

router.post('/create_chat', async (req, res) => {
    const { userA: usernameA, userB: usernameB, isFirstStep, firstMessage } = req.body;
    try {
        // Obtener ObjectIds de usuario basados en los nombres de usuario
        const foundUserA = await User.findOne({ username: usernameA });
        
        const foundUserB = await User.findOne({ username: usernameB });

        if (!foundUserA || !foundUserB) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Si es firstStep, validar que el usuario tenga "primeros pasos" disponibles
        if (isFirstStep) {
            if (foundUserA.firstStepsRemaining <= 0) {
                return res.status(403).json({ 
                    message: 'No first steps remaining',
                    requiresPremium: true 
                });
            }
        }

        // Verificar si ya existe un chat entre los dos usuarios
        let chat = await Chat.findOne({ users: { $all: [foundUserA._id, foundUserB._id] } });

        // Si no existe, crear un nuevo chat
        if (!chat) {
            chat = await Chat.create({ 
                users: [foundUserA._id, foundUserB._id],
                isFirstStep: isFirstStep || false,
                firstStepBy: isFirstStep ? foundUserA._id : null,
                isMatch: !isFirstStep // Si no es firstStep, es match
            });
            
            // Si es firstStep, decrementar el contador
            if (isFirstStep) {
                foundUserA.firstStepsRemaining -= 1;
                foundUserA.firstStepsUsedThisWeek += 1;
                await foundUserA.save();
            }
            
            // Si es firstStep y hay un primer mensaje, agregarlo
            if (isFirstStep && firstMessage) {
                chat.messages.push({
                    sender: foundUserA._id,
                    content: firstMessage,
                    read: false
                });
                await chat.save();
            }
        } else {
            // Si el chat ya existía, verificar si hay match mutuo ahora
            // (esto ocurre cuando B da like a A después de que A dio firstStep)
            if (chat.isFirstStep && !chat.isMatch) {
                // Verificar si ambos usuarios tienen match mutuo
                const userAData = await User.findById(foundUserA._id);
                const userBData = await User.findById(foundUserB._id);
                
                const aLikesB = userAData.isMatch.includes(usernameB);
                const bLikesA = userBData.isMatch.includes(usernameA);
                
                if (aLikesB && bLikesA) {
                    chat.isMatch = true;
                    chat.isFirstStep = false;
                    await chat.save();
                }
            }
        }

        res.status(200).json({ 
            chatId: chat._id,
            firstStepsRemaining: foundUserA.firstStepsRemaining
        });
    } catch (error) {
        console.error('Error al crear el chat:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});


router.post('/send_message', async (req, res) => {
    const { chatId, sender, message } = req.body;

    try {
        // Buscar el chat por su ID
        const chat = await Chat.findById(chatId);

        if (!chat) {
            return res.status(404).json({ message: 'Chat not found' });
        }

        // Buscar el usuario por su nombre de usuario para obtener su _id
        const user = await User.findOne({ username: sender });

        if (!user) {
            return res.status(404).json({ message: 'Sender user not found' });
        }

        // Si es firstStep y no hay match, solo el que inició puede enviar y solo 1 mensaje
        if (chat.isFirstStep && !chat.isMatch) {
            // Verificar si el sender es quien dio el primer paso
            if (chat.firstStepBy.toString() !== user._id.toString()) {
                // El otro usuario NO puede responder hasta que haya match
                return res.status(403).json({ 
                    message: 'Cannot send message. Match required to respond.' 
                });
            }
            
            // Verificar si ya envió un mensaje
            const senderMessages = chat.messages.filter(
                msg => msg.sender.toString() === user._id.toString()
            );
            
            if (senderMessages.length >= 1) {
                return res.status(403).json({ 
                    message: 'First step limit reached. Wait for match to continue.' 
                });
            }
        }

        // Agregar el mensaje al chat con el _id del usuario como remitente
        chat.messages.push({ 
            sender: user._id, 
            content: message,
            read: false
        });
        chat.lastMessage = new Date();
        await chat.save();

        res.status(200).json({ message: 'Message sent successfully' });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Obtener todos los chats de un usuario
router.get('/user_chats/:username', async (req, res) => {
    const { username } = req.params;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const chats = await Chat.find({ users: user._id })
            .populate('users', 'username profilePhoto')
            .populate('messages.sender', 'username')
            .sort({ lastMessage: -1 });

        // Formatear la respuesta
        const formattedChats = chats.map(chat => {
            const otherUser = chat.users.find(u => u.username !== username);
            const lastMessage = chat.messages.length > 0 
                ? chat.messages[chat.messages.length - 1] 
                : null;
            
            // Contar mensajes no leídos del otro usuario
            const unreadCount = chat.messages.filter(msg => 
                msg.sender.username !== username && (msg.read === undefined || !msg.read)
            ).length;

            // profilePhoto ahora es una URL de Cloudinary (String)
            // Mantener compatibilidad con usuarios legacy que tienen Buffer
            let profilePhotoUrl = null;
            if (otherUser?.profilePhoto) {
                if (typeof otherUser.profilePhoto === 'string') {
                    // Es una URL de Cloudinary
                    profilePhotoUrl = otherUser.profilePhoto;
                } else if (Buffer.isBuffer(otherUser.profilePhoto)) {
                    // Legacy: convertir Buffer a base64
                    profilePhotoUrl = otherUser.profilePhoto.toString('base64');
                }
            }

            return {
                chatId: chat._id,
                otherUser: {
                    username: otherUser?.username,
                    profilePhoto: profilePhotoUrl
                },
                lastMessage: lastMessage ? {
                    content: lastMessage.content,
                    sender: lastMessage.sender.username,
                    timestamp: lastMessage.timestamp
                } : null,
                unreadCount: unreadCount,
                isMatch: chat.isMatch || false,
                isFirstStep: chat.isFirstStep || false
            };
        });

        res.status(200).json({ chats: formattedChats });
    } catch (error) {
        console.error('Error fetching user chats:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Obtener mensajes de un chat específico
router.get('/messages/:chatId', async (req, res) => {
    const { chatId } = req.params;

    try {
        const chat = await Chat.findById(chatId)
            .populate('messages.sender', 'username profilePhoto');

        if (!chat) {
            return res.status(404).json({ message: 'Chat not found' });
        }

        res.status(200).json({ messages: chat.messages });
    } catch (error) {
        console.error('Error fetching messages:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Marcar mensajes como leídos
router.post('/mark_as_read', async (req, res) => {
    const { chatId, username } = req.body;

    try {
        const chat = await Chat.findById(chatId).populate('messages.sender', 'username');
        
        if (!chat) {
            return res.status(404).json({ message: 'Chat not found' });
        }

        // Marcar todos los mensajes del otro usuario como leídos
        let updated = false;
        chat.messages.forEach(msg => {
            if (msg.sender.username !== username && !msg.read) {
                msg.read = true;
                updated = true;
            }
        });

        if (updated) {
            await chat.save();
        }

        res.status(200).json({ message: 'Messages marked as read' });
    } catch (error) {
        console.error('Error marking messages as read:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Obtener matches sin conversación iniciada
router.get('/pending_matches/:username', async (req, res) => {
    const { username } = req.params;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Obtener todos los matches del usuario
        const matches = user.isMatch || [];

        // Obtener todos los chats del usuario donde isMatch = true
        const chats = await Chat.find({ 
            users: user._id,
            isMatch: true // Solo matches confirmados
        })
            .populate('users', 'username');

        // Crear un Set con los usernames de usuarios con los que ya tiene chat
        const usersWithChat = new Set();
        chats.forEach(chat => {
            chat.users.forEach(u => {
                if (u.username !== username) {
                    usersWithChat.add(u.username);
                }
            });
        });

        // Filtrar matches que NO tienen chat iniciado
        const pendingMatchUsernames = matches.filter(matchUsername => 
            !usersWithChat.has(matchUsername)
        );

        // Obtener información de los usuarios pendientes
        const pendingMatchUsers = await User.find(
            { username: { $in: pendingMatchUsernames } },
            'username profilePhoto'
        );

        // Formatear la respuesta
        const formattedMatches = pendingMatchUsers.map(matchUser => {
            let profilePhotoUrl = null;
            if (matchUser.profilePhoto) {
                if (typeof matchUser.profilePhoto === 'string') {
                    // Es una URL de Cloudinary
                    profilePhotoUrl = matchUser.profilePhoto;
                } else if (Buffer.isBuffer(matchUser.profilePhoto)) {
                    // Legacy: convertir Buffer a base64
                    profilePhotoUrl = matchUser.profilePhoto.toString('base64');
                }
            }

            return {
                username: matchUser.username,
                profilePhoto: profilePhotoUrl
            };
        });

        res.status(200).json({ matches: formattedMatches });
    } catch (error) {
        console.error('Error fetching pending matches:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Enviar imagen en chat
router.post('/send_image', upload.single('image'), async (req, res) => {
    const { chatId, sender } = req.body;
    const imageFile = req.file;

    console.log('send_image - chatId:', chatId, 'sender:', sender, 'file:', imageFile ? 'presente' : 'ausente');

    if (!imageFile) {
        return res.status(400).json({ 
            message: 'No se proporcionó imagen o el formato no es válido. Solo se permiten imágenes (JPG, PNG, GIF, etc.)' 
        });
    }

    try {
        // Buscar el chat por su ID
        const chat = await Chat.findById(chatId);

        if (!chat) {
            return res.status(404).json({ message: 'Chat not found' });
        }

        // Buscar el usuario por su nombre de usuario
        const user = await User.findOne({ username: sender });

        if (!user) {
            return res.status(404).json({ message: 'Sender user not found' });
        }

        // Subir imagen a Cloudinary
        const result = await uploadImage(imageFile.buffer, {
            folder: 'roomier/chat_images',
            transformation: {
                width: 800,
                height: 800,
                crop: 'limit',
                quality: 'auto:good',
                fetch_format: 'auto'
            }
        });

        // Agregar mensaje de tipo imagen al chat
        const newMessage = {
            sender: user._id,
            content: result.secure_url,
            type: 'image',
            read: false,
            timestamp: new Date()
        };

        chat.messages.push(newMessage);
        chat.lastMessage = new Date();
        await chat.save();

        res.status(200).json({ 
            message: 'Image sent successfully',
            imageUrl: result.secure_url,
            messageData: {
                ...newMessage,
                sender: { username: sender, _id: user._id }
            }
        });
    } catch (error) {
        console.error('Error sending image:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// Obtener firstSteps disponibles de un usuario
router.get('/first_steps_remaining/:username', async (req, res) => {
    const { username } = req.params;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ 
            firstStepsRemaining: user.firstStepsRemaining,
            isPremium: user.isPremium || false
        });
    } catch (error) {
        console.error('Error fetching first steps:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

module.exports = router;
