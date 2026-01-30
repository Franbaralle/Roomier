const express = require('express');
const router = express.Router();
const User = require('../models/user');

// Función para calcular compatibilidad entre dos usuarios
function calculateCompatibility(userA, userB) {
    let score = 0;
    let totalWeight = 0;

    // 1. Compatibilidad de convivencia (50%)
    const convivenceWeight = 50;
    let convivenceScore = 0;
    let convivenceFactors = 0;

    // Horarios
    if (userA.livingHabits?.schedule && userB.livingHabits?.schedule) {
        convivenceScore += (userA.livingHabits.schedule === userB.livingHabits.schedule) ? 100 : 50;
        convivenceFactors++;
    }

    // Limpieza
    if (userA.livingHabits?.cleanliness && userB.livingHabits?.cleanliness) {
        const cleanlinessMap = { low: 1, normal: 2, high: 3 };
        const diff = Math.abs(cleanlinessMap[userA.livingHabits.cleanliness] - cleanlinessMap[userB.livingHabits.cleanliness]);
        convivenceScore += diff === 0 ? 100 : (diff === 1 ? 70 : 30);
        convivenceFactors++;
    }

    // Ruido
    if (userA.livingHabits?.noiseLevel && userB.livingHabits?.noiseLevel) {
        const noiseLevelMap = { quiet: 1, normal: 2, social: 3 };
        const diff = Math.abs(noiseLevelMap[userA.livingHabits.noiseLevel] - noiseLevelMap[userB.livingHabits.noiseLevel]);
        convivenceScore += diff === 0 ? 100 : (diff === 1 ? 60 : 20);
        convivenceFactors++;
    }

    // Nivel social
    if (userA.livingHabits?.socialLevel && userB.livingHabits?.socialLevel) {
        convivenceScore += (userA.livingHabits.socialLevel === userB.livingHabits.socialLevel) ? 100 : 60;
        convivenceFactors++;
    }

    if (convivenceFactors > 0) {
        score += (convivenceScore / convivenceFactors) * (convivenceWeight / 100);
        totalWeight += convivenceWeight;
    }

    // 2. Compatibilidad de zonas (15%)
    const zoneWeight = 15;
    let zoneScore = 0;
    
    if (userA.housingInfo?.preferredZones && userB.housingInfo?.preferredZones) {
        const commonZones = userA.housingInfo.preferredZones.filter(zone => 
            userB.housingInfo.preferredZones.includes(zone)
        );
        if (commonZones.length > 0) {
            zoneScore = 100;
        } else if (userA.housingInfo.generalZone === userB.housingInfo.generalZone) {
            zoneScore = 50;
        }
        score += zoneScore * (zoneWeight / 100);
        totalWeight += zoneWeight;
    }

    // 3. Compatibilidad de presupuesto (10%)
    const budgetWeight = 10;
    let budgetScore = 0;
    
    if (userA.housingInfo?.budgetMin && userA.housingInfo?.budgetMax && 
        userB.housingInfo?.budgetMin && userB.housingInfo?.budgetMax) {
        
        const overlap = Math.min(userA.housingInfo.budgetMax, userB.housingInfo.budgetMax) - 
                       Math.max(userA.housingInfo.budgetMin, userB.housingInfo.budgetMin);
        
        if (overlap > 0) {
            budgetScore = 100;
        }
        
        score += budgetScore * (budgetWeight / 100);
        totalWeight += budgetWeight;
    }

    // 4. Compatibilidad de intereses (15%)
    const interestsWeight = 15;
    let interestsScore = 0;
    
    if (userA.preferences && userB.preferences) {
        let totalCommonInterests = 0;
        let totalPossibleInterests = 0;
        
        // Función para contar tags en una estructura de preferencias
        const countTags = (prefs) => {
            let count = 0;
            if (!prefs || typeof prefs !== 'object') return count;
            
            for (const mainCat in prefs) {
                if (typeof prefs[mainCat] === 'object') {
                    for (const subCat in prefs[mainCat]) {
                        if (Array.isArray(prefs[mainCat][subCat])) {
                            count += prefs[mainCat][subCat].length;
                        }
                    }
                }
            }
            return count;
        };
        
        // Función para obtener todos los tags de las preferencias
        const getAllTags = (prefs) => {
            const tags = [];
            if (!prefs || typeof prefs !== 'object') return tags;
            
            for (const mainCat in prefs) {
                if (typeof prefs[mainCat] === 'object') {
                    for (const subCat in prefs[mainCat]) {
                        if (Array.isArray(prefs[mainCat][subCat])) {
                            tags.push(...prefs[mainCat][subCat]);
                        }
                    }
                }
            }
            return tags;
        };
        
        const tagsA = getAllTags(userA.preferences);
        const tagsB = getAllTags(userB.preferences);
        
        // Contar intereses comunes
        totalCommonInterests = tagsA.filter(tag => tagsB.includes(tag)).length;
        totalPossibleInterests = Math.max(tagsA.length, tagsB.length, 1);
        
        interestsScore = (totalCommonInterests / totalPossibleInterests) * 100;
        score += interestsScore * (interestsWeight / 100);
        totalWeight += interestsWeight;
    }

    // 5. Compatibilidad de estilo de vida (10%)
    const lifestyleWeight = 10;
    let lifestyleScore = 0;
    let lifestyleFactors = 0;

    if (userA.livingHabits?.drinker && userB.livingHabits?.drinker) {
        lifestyleScore += (userA.livingHabits.drinker === userB.livingHabits.drinker) ? 100 : 60;
        lifestyleFactors++;
    }

    if (lifestyleFactors > 0) {
        score += (lifestyleScore / lifestyleFactors) * (lifestyleWeight / 100);
        totalWeight += lifestyleWeight;
    }

    return totalWeight > 0 ? Math.round(score) : 0;
}

// Función para verificar deal breakers
function checkDealBreakers(userA, userB) {
    // Si A no acepta fumadores y B fuma
    if (userA.dealBreakers?.noSmokers && userB.livingHabits?.smoker) {
        return false;
    }

    // Si A no acepta mascotas y B tiene mascotas
    if (userA.dealBreakers?.noPets && userB.livingHabits?.hasPets) {
        return false;
    }

    // Si A no acepta fiestas y B es muy social/ruidoso
    if (userA.dealBreakers?.noParties && userB.livingHabits?.noiseLevel === 'social') {
        return false;
    }

    // Verificar en el sentido inverso también
    if (userB.dealBreakers?.noSmokers && userA.livingHabits?.smoker) {
        return false;
    }

    if (userB.dealBreakers?.noPets && userA.livingHabits?.hasPets) {
        return false;
    }

    if (userB.dealBreakers?.noParties && userA.livingHabits?.noiseLevel === 'social') {
        return false;
    }

    return true;
}

// Función para verificar preferencias de roommate (género y edad)
function checkRoommatePreferences(userA, userB) {
    // Verificar preferencia de género de A hacia B
    if (userA.roommatePreferences?.gender && userB.gender) {
        if (userA.roommatePreferences.gender !== 'both' && 
            userA.roommatePreferences.gender !== userB.gender) {
            return false;
        }
    }

    // Verificar preferencia de género de B hacia A
    if (userB.roommatePreferences?.gender && userA.gender) {
        if (userB.roommatePreferences.gender !== 'both' && 
            userB.roommatePreferences.gender !== userA.gender) {
            return false;
        }
    }

    // Verificar rango de edad de A hacia B
    if (userA.roommatePreferences?.ageMin && userA.roommatePreferences?.ageMax && userB.birthdate) {
        const ageB = calculateAge(userB.birthdate);
        if (ageB < userA.roommatePreferences.ageMin || ageB > userA.roommatePreferences.ageMax) {
            return false;
        }
    }

    // Verificar rango de edad de B hacia A
    if (userB.roommatePreferences?.ageMin && userB.roommatePreferences?.ageMax && userA.birthdate) {
        const ageA = calculateAge(userA.birthdate);
        if (ageA < userB.roommatePreferences.ageMin || ageA > userB.roommatePreferences.ageMax) {
            return false;
        }
    }

    return true;
}

// Función auxiliar para calcular edad
function calculateAge(birthdate) {
    const today = new Date();
    const birth = new Date(birthdate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
        age--;
    }
    return age;
}

// Función para verificar compatibilidad de presupuesto
function checkBudgetCompatibility(userA, userB) {
    if (!userA.housingInfo?.budgetMin || !userA.housingInfo?.budgetMax || 
        !userB.housingInfo?.budgetMin || !userB.housingInfo?.budgetMax) {
        return true; // Si no hay info de presupuesto, permitir
    }

    // Verificar si hay overlap en los rangos de presupuesto
    return (userA.housingInfo.budgetMin <= userB.housingInfo.budgetMax) && 
           (userB.housingInfo.budgetMin <= userA.housingInfo.budgetMax);
}

router.get('/', async (req, res) => {
    try {
        const currentUsername = req.query.currentUser; // Obtener usuario actual desde query params

        if (!currentUsername) {
            return res.status(400).json({ message: 'Se requiere el usuario actual' });
        }

        // Obtener el usuario actual
        const currentUser = await User.findOne({ username: currentUsername });
        
        if (!currentUser) {
            return res.status(404).json({ message: 'Usuario actual no encontrado' });
        }

        // Obtener todos los usuarios excepto:
        // - El usuario actual
        // - Usuarios ya matcheados
        // - Usuarios rechazados
        // - Usuarios bloqueados (por ti o que te bloquearon)
        const excludedUsernames = [
            currentUsername,
            ...(currentUser.isMatch || []),
            ...(currentUser.notMatch || []),
            ...(currentUser.blockedUsers || []) // Usuarios que bloqueaste
        ];

        // Obtener usuarios que te bloquearon
        const usersWhoBlockedMe = await User.find({ 
            blockedUsers: currentUsername 
        }).select('username');
        
        const blockedByUsernames = usersWhoBlockedMe.map(u => u.username);
        excludedUsernames.push(...blockedByUsernames);

        // Filtrar por hasPlace: mostrar solo usuarios complementarios
        // Si tengo lugar (true), mostrar solo usuarios sin lugar (false)
        // Si no tengo lugar (false), mostrar solo usuarios con lugar (true)
        const currentHasPlace = currentUser.housingInfo?.hasPlace || false;
        const targetHasPlace = !currentHasPlace;

        let potentialMatches = await User.find({ 
            username: { $nin: excludedUsernames },
            'housingInfo.hasPlace': targetHasPlace
        }).lean(); // Usar .lean() para incluir campos legacy del schema

        // Filtrar por deal breakers, presupuesto y preferencias de roommate
        potentialMatches = potentialMatches.filter(user => {
            // Verificar deal breakers
            if (!checkDealBreakers(currentUser, user)) {
                return false;
            }

            // Verificar preferencias de roommate (género y edad)
            if (!checkRoommatePreferences(currentUser, user)) {
                return false;
            }

            // Verificar compatibilidad de presupuesto
            if (!checkBudgetCompatibility(currentUser, user)) {
                return false;
            }

            return true;
        });

        // Calcular compatibilidad para cada usuario
        const profilesWithCompatibility = potentialMatches.map(user => {
            const compatibility = calculateCompatibility(currentUser, user);
            
            // No enviar datos sensibles al frontend
            // Con .lean() ya es un objeto plano, no necesitamos .toObject()
            delete user.housingInfo?.budgetMin;
            delete user.housingInfo?.budgetMax;
            delete user.housingInfo?.preferredZones; // Privado hasta match
            delete user.personalInfo?.religion;
            delete user.personalInfo?.politicPreference;
            delete user.verification;
            delete user.verificationCode;
            delete user.password;
            delete user.isMatch;
            delete user.notMatch;
            delete user.reportedBy;
            delete user.blockedUsers;
            delete user.revealedInfo;

            // Extraer foto principal para compatibilidad con frontend
            let primaryPhotoUrl = null;
            if (user.profilePhotos && user.profilePhotos.length > 0) {
                primaryPhotoUrl = user.profilePhotos[0].url;
            } else if (user.profilePhoto) {
                primaryPhotoUrl = user.profilePhoto;
            }
            
            return {
                ...user,
                profilePhoto: primaryPhotoUrl, // Asegurar que siempre haya profilePhoto
                compatibility
            };
        });

        // Ordenar por compatibilidad (mayor a menor)
        profilesWithCompatibility.sort((a, b) => b.compatibility - a.compatibility);

        // Retornar los mejores 20 perfiles
        res.status(200).json(profilesWithCompatibility.slice(0, 20));
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error del servidor' });
    }
});

// Endpoint para obtener usuarios que te dieron like
router.get('/received-likes', async (req, res) => {
    try {
        const currentUsername = req.query.currentUser;

        if (!currentUsername) {
            return res.status(400).json({ message: 'Se requiere el usuario actual' });
        }

        // Obtener el usuario actual
        const currentUser = await User.findOne({ username: currentUsername });
        
        if (!currentUser) {
            return res.status(404).json({ message: 'Usuario actual no encontrado' });
        }

        // Encontrar usuarios que tienen a currentUsername en su lista isMatch
        // pero currentUsername no los tiene en su isMatch (no son match mutuo)
        const usersWhoLikedMe = await User.find({
            isMatch: currentUsername,
            username: { $nin: currentUser.isMatch || [] } // No son match mutuo
        }).lean(); // Usar .lean() para incluir campos legacy

        // Formatear la respuesta con información básica
        const receivedLikes = usersWhoLikedMe.map(user => {
            // Calcular edad
            let age = null;
            if (user.birthdate) {
                age = calculateAge(user.birthdate);
            }

            // Extraer foto principal
            let primaryPhotoUrl = null;
            if (user.profilePhotos && user.profilePhotos.length > 0) {
                primaryPhotoUrl = user.profilePhotos[0].url;
            } else if (user.profilePhoto) {
                primaryPhotoUrl = user.profilePhoto;
            }

            // Retornar solo información básica
            return {
                username: user.username,
                age: age,
                gender: user.gender,
                profilePhotos: user.profilePhotos,
                profilePhoto: primaryPhotoUrl, // Foto principal unificada
                personalInfo: {
                    job: user.personalInfo?.job,
                    aboutMe: user.personalInfo?.aboutMe
                }
            };
        });

        res.status(200).json(receivedLikes);
    } catch (error) {
        console.error('Error al obtener likes recibidos:', error);
        res.status(500).json({ message: 'Error del servidor' });
    }
});

module.exports = router;