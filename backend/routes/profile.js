const express = require('express');
const router = express.Router();
const User = require('../models/user');
const { verifyToken } = require('../middleware/auth');
const logger = require('../utils/logger');

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
            livingHabits: user.livingHabits, // Hábitos de convivencia
            housingInfo: {
                hasPlace: user.housingInfo?.hasPlace,
                moveInDate: user.housingInfo?.moveInDate,
                stayDuration: user.housingInfo?.stayDuration,
                city: user.housingInfo?.city,
                generalZone: user.housingInfo?.generalZone,
                preferredZones: user.housingInfo?.preferredZones, // Incluir para revelación
                budgetMin: user.housingInfo?.budgetMin, // Incluir para revelación
                budgetMax: user.housingInfo?.budgetMax, // Incluir para revelación
                // NOTA: El frontend filtrará estos campos privados según revelación
            },
            dealBreakers: user.dealBreakers,
            verification: {
                emailVerified: user.verification?.emailVerified,
                phoneVerified: user.verification?.phoneVerified,
                idVerified: user.verification?.idVerified,
                selfieVerified: user.verification?.selfieVerified,
            },
            profilePhoto: user.profilePhoto,
            chatId: user.chatId, // Agregar el campo chatId al perfil
            isMatch: user.isMatch || [], // Lista de usuarios con los que hizo match
            notMatch: user.notMatch || [], // Lista de usuarios que rechazó
            revealedInfo: user.revealedInfo || [] // Agregar información de revelación
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

router.post('/unmatch/:username', async (req, res) => {
    const { username } = req.params;
    const { currentUserUsername } = req.body;

    try {
        // Eliminar el match en ambas direcciones de isMatch y notMatch
        await User.findOneAndUpdate(
            { username: username },
            { 
                $pull: { 
                    isMatch: currentUserUsername,
                    notMatch: currentUserUsername 
                } 
            }
        );

        await User.findOneAndUpdate(
            { username: currentUserUsername },
            { 
                $pull: { 
                    isMatch: username,
                    notMatch: username
                } 
            }
        );

        res.status(200).json({ message: 'Match deshecho correctamente' });
    } catch (error) {
        console.error('Error al deshacer el match:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para revelar información adicional después del match
router.post('/reveal_info', async (req, res) => {
    try {
        const { currentUsername, matchedUsername, infoType } = req.body;
        
        logger.debug(`Reveal info request: currentUsername=${currentUsername}, matchedUsername=${matchedUsername}, infoType=${infoType}`);

        // Validar parámetros
        if (!currentUsername || !matchedUsername || !infoType) {
            return res.status(400).json({ message: 'Faltan parámetros requeridos' });
        }

        // Verificar que ambos usuarios existen y tienen match
        const currentUser = await User.findOne({ username: currentUsername });
        const matchedUser = await User.findOne({ username: matchedUsername });

        if (!currentUser || !matchedUser) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.debug(`Current user isMatch: ${JSON.stringify(currentUser.isMatch)}, includes matchedUsername: ${currentUser.isMatch.includes(matchedUsername)}`);

        // Verificar que realmente hay un match
        if (!currentUser.isMatch.includes(matchedUsername)) {
            return res.status(403).json({ message: 'No hay match con este usuario' });
        }

        // Buscar o crear el registro de revelación de información
        let revealedInfoEntry = currentUser.revealedInfo.find(
            info => info.matchedUser === matchedUsername
        );

        logger.debug(`Existing revealedInfoEntry: ${JSON.stringify(revealedInfoEntry)}`);

        if (!revealedInfoEntry) {
            revealedInfoEntry = {
                matchedUser: matchedUsername,
                revealedZones: false,
                revealedBudget: false,
                revealedContact: false
            };
            currentUser.revealedInfo.push(revealedInfoEntry);
        }

        // Actualizar el campo específico
        switch (infoType) {
            case 'zones':
                revealedInfoEntry.revealedZones = true;
                break;
            case 'budget':
                revealedInfoEntry.revealedBudget = true;
                break;
            case 'contact':
                revealedInfoEntry.revealedContact = true;
                break;
            default:
                return res.status(400).json({ message: 'Tipo de información no válido' });
        }

        logger.debug(`Updated revealedInfoEntry: ${JSON.stringify(revealedInfoEntry)}`);

        await currentUser.save();

        logger.info(`User ${currentUsername} revealed ${infoType} info to ${matchedUsername}`);

        res.status(200).json({ 
            message: 'Información revelada correctamente',
            revealedInfo: revealedInfoEntry
        });
    } catch (error) {
        console.error('[DEBUG ERROR] Error al revelar información:', error);
        res.status(500).json({ message: 'Error interno del servidor' });
    }
});

module.exports = router;