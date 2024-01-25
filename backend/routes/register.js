// routes/register.js
const express = require('express');
const router = express.Router();
const User = require('../models/user');

// Ruta para manejar la fecha de nacimiento durante el registro
router.post('/register/date', async (req, res) => {
    const { username, birthdate } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        user.birthdate = birthdate;
        await user.save();

        return res.json({ message: 'Fecha de nacimiento actualizada exitosamente durante el registro' });
    } catch (error) {
        console.error('Error al actualizar la fecha de nacimiento durante el registro:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar las preferencias durante el registro
router.post('/register/preferences', async (req, res) => {
    const { username, preferences } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        user.preferences = preferences;
        await user.save();

        return res.json({ message: 'Preferencias actualizadas exitosamente durante el registro' });
    } catch (error) {
        console.error('Error al actualizar las preferencias durante el registro:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar la información personal durante el registro
router.post('/register/personal_info', async (req, res) => {
    const { username, personalInfo } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        user.personalInfo = personalInfo;
        await user.save();

        return res.json({ message: 'Información personal actualizada exitosamente durante el registro' });
    } catch (error) {
        console.error('Error al actualizar la información personal durante el registro:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar la foto de perfil durante el registro
router.post('/register/profile_photo', async (req, res) => {
    const { username, profilePhoto } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        user.profilePhoto = profilePhoto;
        await user.save();

        return res.json({ message: 'Foto de perfil actualizada exitosamente durante el registro' });
    } catch (error) {
        console.error('Error al actualizar la foto de perfil durante el registro:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

module.exports = router;
