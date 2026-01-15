const express = require('express');
const router = express.Router();
const User = require('../models/user');
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
        if (occupation !== undefined) updateData['personalInfo.occupation'] = occupation.trim();
        if (religion !== undefined) updateData['personalInfo.religion'] = religion.trim();
        if (politicalViews !== undefined) updateData['personalInfo.politicalViews'] = politicalViews.trim();
        if (bio !== undefined) updateData['personalInfo.bio'] = bio.trim();

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
            originProvince,
            destinationProvince,
            specificNeighborhoodsOrigin,
            specificNeighborhoodsDestination,
            budgetMin, 
            budgetMax,
            // Legacy fields
            city,
            generalZone, 
            preferredZones
        } = req.body;

        // Validaciones
        if (budgetMin && budgetMax && budgetMin > budgetMax) {
            return res.status(400).json({ message: 'El presupuesto mínimo no puede ser mayor al máximo' });
        }

        const updateData = {};
        if (hasPlace !== undefined) updateData['housingInfo.hasPlace'] = hasPlace;
        if (moveInDate !== undefined) updateData['housingInfo.moveInDate'] = moveInDate.trim();
        if (stayDuration !== undefined) updateData['housingInfo.stayDuration'] = stayDuration.trim();
        
        // Nuevos campos (aplicar trim)
        if (originProvince !== undefined) updateData['housingInfo.originProvince'] = originProvince.trim();
        if (destinationProvince !== undefined) updateData['housingInfo.destinationProvince'] = destinationProvince.trim();
        if (specificNeighborhoodsOrigin !== undefined) updateData['housingInfo.specificNeighborhoodsOrigin'] = specificNeighborhoodsOrigin.map(n => n.trim());
        if (specificNeighborhoodsDestination !== undefined) updateData['housingInfo.specificNeighborhoodsDestination'] = specificNeighborhoodsDestination.map(n => n.trim());
        
        // Legacy fields (mantener para compatibilidad, aplicar trim)
        if (city !== undefined) updateData['housingInfo.city'] = city.trim();
        if (generalZone !== undefined) updateData['housingInfo.generalZone'] = generalZone.trim();
        if (preferredZones !== undefined) updateData['housingInfo.preferredZones'] = preferredZones.map(z => z.trim());
        
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

// PUT /api/edit-profile/tags
// Actualizar tags de intereses estructurados (convivencia, gastronomía, etc.)
router.put('/tags', verifyToken, async (req, res) => {
    try {
        const username = req.user.username;
        const { preferences } = req.body;

        // Validar estructura de preferencias
        if (!preferences || typeof preferences !== 'object') {
            return res.status(400).json({ message: 'Preferencias inválidas' });
        }

        // Categorías válidas
        const validCategories = ['convivencia', 'gastronomia', 'deporte', 'entretenimiento', 'creatividad', 'interesesSociales'];
        
        // Limpiar y validar preferencias
        const cleanedPreferences = {};
        for (const mainCat of validCategories) {
            if (preferences[mainCat]) {
                cleanedPreferences[mainCat] = {};
                for (const subCat in preferences[mainCat]) {
                    if (preferences[mainCat][subCat] && Array.isArray(preferences[mainCat][subCat])) {
                        // Limitar a 5 tags por subcategoría
                        cleanedPreferences[mainCat][subCat] = preferences[mainCat][subCat].slice(0, 5);
                    } else {
                        cleanedPreferences[mainCat][subCat] = [];
                    }
                }
            }
        }

        const user = await User.findOneAndUpdate(
            { username },
            { $set: { preferences: cleanedPreferences } },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        logger.info(`Tags/preferences updated for user: ${username}`);
        
        res.json({ 
            message: 'Tags actualizados exitosamente', 
            preferences: user.preferences 
        });
    } catch (error) {
        logger.error(`Error updating tags: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar tags' });
    }
});

module.exports = router;
