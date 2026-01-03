const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { verifyToken } = require('../middleware/auth');
const logger = require('../utils/logger');

// PUT /api/edit-profile/personal-info
// Actualizar información personal (trabajo, religión, política, descripción)
router.put('/personal-info', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { occupation, religion, politicalViews, bio } = req.body;

        // Validaciones básicas
        if (bio && bio.length > 500) {
            return res.status(400).json({ message: 'La biografía no puede superar 500 caracteres' });
        }

        const updateData = {};
        if (occupation !== undefined) updateData['personalInfo.occupation'] = occupation;
        if (religion !== undefined) updateData['personalInfo.religion'] = religion;
        if (politicalViews !== undefined) updateData['personalInfo.politicalViews'] = politicalViews;
        if (bio !== undefined) updateData['personalInfo.bio'] = bio;

        const user = await User.findOneAndUpdate(
            { username },
            { $set: updateData },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Personal info updated for user: ${username}`);
        
        res.json({ 
            message: 'Información personal actualizada', 
            personalInfo: user.personalInfo 
        });
    } catch (error) {
        logger.error(`Error updating personal info: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar información personal' });
    }
});

// PUT /api/edit-profile/interests
// Actualizar intereses (hasta 5)
router.put('/interests', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { interests } = req.body;

        if (!Array.isArray(interests)) {
            return res.status(400).json({ message: 'Los intereses deben ser un array' });
        }

        if (interests.length > 5) {
            return res.status(400).json({ message: 'Máximo 5 intereses permitidos' });
        }

        // Validar que cada interés sea un string no vacío
        const validInterests = interests.every(i => typeof i === 'string' && i.trim().length > 0);
        if (!validInterests) {
            return res.status(400).json({ message: 'Cada interés debe ser un texto válido' });
        }

        const user = await User.findOneAndUpdate(
            { username },
            { $set: { 'personalInfo.interests': interests } },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Interests updated for user: ${username}`);
        
        res.json({ 
            message: 'Intereses actualizados', 
            interests: user.personalInfo.interests 
        });
    } catch (error) {
        logger.error(`Error updating interests: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar intereses' });
    }
});

// PUT /api/edit-profile/living-habits
// Actualizar hábitos de convivencia
router.put('/living-habits', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { 
            smoker, 
            pets, 
            cleanliness, 
            noiseLevel, 
            scheduleType, 
            socialLevel, 
            guestsFrequency, 
            drinker, 
            roommateGender 
        } = req.body;

        const updateData = {};
        if (smoker !== undefined) updateData['livingHabits.smoker'] = smoker;
        if (pets !== undefined) updateData['livingHabits.pets'] = pets;
        if (cleanliness !== undefined) updateData['livingHabits.cleanliness'] = cleanliness;
        if (noiseLevel !== undefined) updateData['livingHabits.noiseLevel'] = noiseLevel;
        if (scheduleType !== undefined) updateData['livingHabits.scheduleType'] = scheduleType;
        if (socialLevel !== undefined) updateData['livingHabits.socialLevel'] = socialLevel;
        if (guestsFrequency !== undefined) updateData['livingHabits.guestsFrequency'] = guestsFrequency;
        if (drinker !== undefined) updateData['livingHabits.drinker'] = drinker;
        if (roommateGender !== undefined) updateData['livingHabits.roommateGender'] = roommateGender;

        const user = await User.findOneAndUpdate(
            { username },
            { $set: updateData },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Living habits updated for user: ${username}`);
        
        res.json({ 
            message: 'Hábitos de convivencia actualizados', 
            livingHabits: user.livingHabits 
        });
    } catch (error) {
        logger.error(`Error updating living habits: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar hábitos de convivencia' });
    }
});

// PUT /api/edit-profile/housing-info
// Actualizar información de vivienda
router.put('/housing-info', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { 
            hasPlace, 
            moveInDate, 
            stayDuration, 
            city, 
            generalZone, 
            preferredZones, 
            budgetMin, 
            budgetMax 
        } = req.body;

        // Validaciones
        if (budgetMin && budgetMax && budgetMin > budgetMax) {
            return res.status(400).json({ message: 'El presupuesto mínimo no puede ser mayor al máximo' });
        }

        const updateData = {};
        if (hasPlace !== undefined) updateData['housingInfo.hasPlace'] = hasPlace;
        if (moveInDate !== undefined) updateData['housingInfo.moveInDate'] = moveInDate;
        if (stayDuration !== undefined) updateData['housingInfo.stayDuration'] = stayDuration;
        if (city !== undefined) updateData['housingInfo.city'] = city;
        if (generalZone !== undefined) updateData['housingInfo.generalZone'] = generalZone;
        if (preferredZones !== undefined) updateData['housingInfo.preferredZones'] = preferredZones;
        if (budgetMin !== undefined) updateData['housingInfo.budgetMin'] = budgetMin;
        if (budgetMax !== undefined) updateData['housingInfo.budgetMax'] = budgetMax;

        const user = await User.findOneAndUpdate(
            { username },
            { $set: updateData },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Housing info updated for user: ${username}`);
        
        res.json({ 
            message: 'Información de vivienda actualizada', 
            housingInfo: user.housingInfo 
        });
    } catch (error) {
        logger.error(`Error updating housing info: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar información de vivienda' });
    }
});

// PUT /api/edit-profile/deal-breakers
// Actualizar deal-breakers
router.put('/deal-breakers', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { dealBreakers } = req.body;

        if (!Array.isArray(dealBreakers)) {
            return res.status(400).json({ message: 'Los deal-breakers deben ser un array' });
        }

        const user = await User.findOneAndUpdate(
            { username },
            { $set: { dealBreakers } },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Deal breakers updated for user: ${username}`);
        
        res.json({ 
            message: 'Deal-breakers actualizados', 
            dealBreakers: user.dealBreakers 
        });
    } catch (error) {
        logger.error(`Error updating deal breakers: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar deal-breakers' });
    }
});

// PUT /api/edit-profile/preferences
// Actualizar preferencias generales (género, edad)
router.put('/preferences', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { gender, ageMin, ageMax } = req.body;

        // Validaciones
        if (ageMin && ageMax && ageMin > ageMax) {
            return res.status(400).json({ message: 'La edad mínima no puede ser mayor a la máxima' });
        }

        if (ageMin && (ageMin < 18 || ageMin > 100)) {
            return res.status(400).json({ message: 'Edad mínima inválida' });
        }

        if (ageMax && (ageMax < 18 || ageMax > 100)) {
            return res.status(400).json({ message: 'Edad máxima inválida' });
        }

        const updateData = {};
        if (gender !== undefined) updateData['preferences.gender'] = gender;
        if (ageMin !== undefined) updateData['preferences.ageMin'] = ageMin;
        if (ageMax !== undefined) updateData['preferences.ageMax'] = ageMax;

        const user = await User.findOneAndUpdate(
            { username },
            { $set: updateData },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Preferences updated for user: ${username}`);
        
        res.json({ 
            message: 'Preferencias actualizadas', 
            preferences: user.preferences 
        });
    } catch (error) {
        logger.error(`Error updating preferences: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar preferencias' });
    }
});

module.exports = router;
