const express = require('express');
const router = express.Router();
const Chat = require('../models/chatModel');
const User = require('../models/user');

router.post('/create_chat', async (req, res) => {
    const { userA: usernameA, userB: usernameB } = req.body;
    console.log('Request body:', req.body);
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
        chat.messages.push({ sender: user._id, content: message });
        await chat.save();

        res.status(200).json({ message: 'Message sent successfully' });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});


module.exports = router;
