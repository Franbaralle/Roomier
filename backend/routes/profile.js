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

router.put('/:username', async (req, res) => {
    try {
        const username = req.params.username;
        const updatedProfileData = req.body;
        console.log(req.params.username);

        // Extraer el campo que se está modificando y su nuevo valor
        const { job, religion, politicPreference, aboutMe } = updatedProfileData;

        // Construir el objeto de actualización
        const updateFields = {};
        if (job) {
            updateFields['personalInfo.job'] = job;
        }
        if (religion) {
            updateFields['personalInfo.religion'] = religion;
        }
        if (politicPreference) {
            updateFields['personalInfo.politicPreference'] = politicPreference;
        }
        if (aboutMe) {
            updateFields['personalInfo.aboutMe'] = aboutMe;
        }
        // Actualizar el perfil en la base de datos
        await User.findOneAndUpdate({ username }, { $set: updateFields }, { new: true });
        res.status(200).json({ message: 'Perfil actualizado correctamente' });
    } catch (error) {
        console.error('Error al actualizar el perfil:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

router.post('/match_profile/:username', async (req, res) => {
    const { username } = req.params;
    const { isMatched, currentUserUsername } = req.body;

    console.log('Username:', username);
    console.log('isMatched:', isMatched); // Aquí deberías ver el valor booleano isMatched

    try {
        let updateField;
        if (isMatched) {
            updateField = { $addToSet: { isMatch: currentUserUsername } };
        } else {
            updateField = { $addToSet: { notMatch: currentUserUsername } };
        }

        const user = await User.findOneAndUpdate(
            { username: username },
            updateField,
            { new: true }
        );

        console.log('User:', user);

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        return res.status(200).json({ message: 'Perfil actualizado correctamente' });
    } catch (error) {
        console.error('Error al actualizar el perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

router.post('/check_match/:username', async (req, res) => {
    const { username } = req.params;
    const { currentUserUsername } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Verificar si currentUserUsername está en la lista de coincidencias de username
        const isMatch = user.isMatch.includes(currentUserUsername);

        res.status(200).json({ isMatch });
    } catch (error) {
        console.error('Error al verificar la coincidencia:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

module.exports = router;