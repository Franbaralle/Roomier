// routes/register.js
const multer = require('multer');
const fs = require('fs');
const storage = multer.diskStorage({
    destination: function (req, file, cb){
        const destinationPath = '../uploads'

        fs.mkdirSync(destinationPath, { recursive: true });

        cb(null, destinationPath);
    },
    filename: function (req, file, cb){
        cb(null, file.fieldname + '-' + Date.now() + '.jpg')
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // Establece el límite en 10 MB, ajusta según tus necesidades
    },
});
const express = require('express');
const router = express.Router();
const User = require('../models/user');

router.use('/profile_photo', upload.single('profilePhoto'), (req, res, next) => {
    if (!req.file) {
        return res.status(400).json({ message: 'No se proporcionó ninguna imagen' });
    }

    // Puedes acceder a la imagen a través de req.file.buffer
    req.body.profilePhoto = req.file.buffer;

    next();
});

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

        // Manejar específicamente el error de duplicado en MongoDB
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

        // Actualiza cada campo de personalInfo solo si está presente en la solicitud
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
