const express = require('express');
const router = express.Router();
const User = require('../models/user');
const Chat = require('../models/chatModel');

router.post('/', async (req, res) => {
    const { users } = req.body;
    try {
        const newChat = await Chat.create({ users });
        res.status(201).json(newChat);
    } catch (error) {
        console.error('Error al crear el chat:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Obtener todos los chats de un usuario por su nombre de usuario
router.get('/:username', async (req, res) => {
    const { username } = req.params;
    try {
        // Primero, buscamos al usuario por su nombre de usuario para obtener su ID
        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }
        const userId = user._id;

        // Luego, buscamos todos los chats en los que el usuario participe
        const chats = await Chat.find({ users: userId }).populate('users', 'username');
        res.status(200).json(chats);
    } catch (error) {
        console.error('Error al obtener los chats:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

module.exports = router;
