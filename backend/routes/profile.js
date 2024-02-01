const express = require('express');
const router = express.Router();
const User = require('../models/user');

// Ruta para obtener información del perfil
router.get('/:username', async (req, res) => {
    try {
        const username = req.params.username;
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Aquí puedes personalizar qué información del perfil deseas enviar al cliente
        const profileInfo = {
            username: user.username,
            email: user.email,
            birthdate: user.birthdate,
            preferences: user.preferences,
            personalInfo: user.personalInfo,
            profilePhoto: user.profilePhoto
        };

        if (user.profilePhoto) {
            const profilePhotoBase64 = user.profilePhoto.toString('base64');
            profileInfo.profilePhoto = profilePhotoBase64;
        }

        res.status(200).json(profileInfo);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error del servidor' });
    }
});

module.exports = router;