const express = require('express');
const router = express.Router();
const Chat = require('../models/chatModel');
const User = require('../models/user');

router.post('/create_chat', async (req, res) => {
    const { userA: usernameA, userB: usernameB } = req.body;
    try {
        // Obtener ObjectIds de usuario basados en los nombres de usuario
        const foundUserA = await User.findOne({ username: usernameA });
        
        const foundUserB = await User.findOne({ username: usernameB });

        if (!foundUserA || !foundUserB) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Verificar si ya existe un chat entre los dos usuarios
        let chat = await Chat.findOne({ users: { $all: [foundUserA._id, foundUserB._id] } });

        // Si no existe, crear un nuevo chat
        if (!chat) {
            chat = await Chat.create({ users: [foundUserA._id, foundUserB._id] });
        }

        res.status(200).json({ chatId: chat._id });
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

            // Convertir profilePhoto a base64 si es un Buffer
            let profilePhotoBase64 = null;
            if (otherUser?.profilePhoto) {
                if (Buffer.isBuffer(otherUser.profilePhoto)) {
                    profilePhotoBase64 = otherUser.profilePhoto.toString('base64');
                } else if (typeof otherUser.profilePhoto === 'string') {
                    profilePhotoBase64 = otherUser.profilePhoto;
                }
            }

            return {
                chatId: chat._id,
                otherUser: {
                    username: otherUser?.username,
                    profilePhoto: profilePhotoBase64
                },
                lastMessage: lastMessage ? {
                    content: lastMessage.content,
                    sender: lastMessage.sender.username,
                    timestamp: lastMessage.timestamp
                } : null,
                unreadCount: unreadCount
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

module.exports = router;
