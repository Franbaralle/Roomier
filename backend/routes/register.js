// routes/register.js
const express = require('express');
const multer = require('multer');
const storage = multer.memoryStorage();
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024,
    },
});
const router = express.Router();
const User = require('../models/user');

// Ruta para manejar las preferencias durante el registro
router.post('/preferences', async (req, res) => {
    const { username, preferences } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        if (!Array.isArray(preferences)) {
            return res.status(400).json({ message: 'Las preferencias deben ser proporcionadas como un array' });
        }

        user.preferences = preferences;
        await user.save();

        return res.json({ message: 'Preferencias actualizadas exitosamente durante el registro' });
    } catch (error) {
        console.error('Error al actualizar las preferencias durante el registro:', error);

        if (error.name === 'MongoError' && error.code === 11000) {
            return res.status(400).json({ message: 'Error de duplicado. Ya existen preferencias para este usuario.' });
        }

        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar la información personal durante el registro
router.post('/personal_info', async (req, res) => {
    const { username, personalInfo } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        if (personalInfo.job !== undefined) {
            user.personalInfo.job = personalInfo.job;
        }
        if (personalInfo.religion !== undefined) {
            user.personalInfo.religion = personalInfo.religion;
        }
        if (personalInfo.politicPreference !== undefined) {
            user.personalInfo.politicPreference = personalInfo.politicPreference;
        }
        if (personalInfo.aboutMe !== undefined) {
            user.personalInfo.aboutMe = personalInfo.aboutMe;
        }

        await user.save();

        return res.json({ message: 'Información personal actualizada exitosamente durante el registro' });
    } catch (error) {
        console.error('Error al actualizar la información personal durante el registro:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar la foto de perfil durante el registro
router.post('/profile_photo', upload.single('profilePhoto'), async (req, res) => {
    try {
        const { username } = req.body;
        if (!req.file) {
            return res.status(400).json({ message: 'No se proporcionó ninguna imagen' });
        }
        const profilePhoto = req.file.buffer;

        const user = await User.findOne({ username });


        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        user.profilePhoto = profilePhoto;
        await user.save();

        return res.json({ message: 'Foto de perfil actualizada exitosamente' });
    } catch (error) {
        console.error('Error al actualizar la foto de perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

module.exports = router;
