const express = require('express');
const bcrypt = require('bcrypt');
const { Resend } = require('resend');
const multer = require('multer');
const { uploadImage } = require('../utils/cloudinary');
const storage = multer.memoryStorage();
const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024,
    },
});
const router = express.Router();
const User = require('../models/user');

const sendVerificationEmail = async (to, verificationCode) => {
    try {
        console.log('[EMAIL] Iniciando envío a:', to);
        
        const resend = new Resend(process.env.RESEND_API_KEY);
        
        const { data, error } = await resend.emails.send({
            from: 'Roomier <onboarding@resend.dev>', // Usar dominio verificado de Resend
            to: [to],
            subject: 'Confirmación de Registro',
            html: `<h2>¡Bienvenido a Roomier!</h2><p>Tu código de verificación es: <strong>${verificationCode}</strong></p>`,
        });

        if (error) {
            console.error('[EMAIL] Error de Resend:', error);
            throw error;
        }

        console.log('[EMAIL] Email enviado exitosamente:', data.id);
    } catch (error) {
        console.error('[EMAIL] Error al enviar el correo electrónico de verificación:', error);
        throw error; // Re-lanzar el error para que el endpoint lo capture
    }
};

const generateVerificationCode = () => {
    // Lógica para generar un código de verificación único (puedes usar cualquier lógica que desees)
    const codeLength = 6;
    const characters = '0123456789';
    let verificationCode = '';

    for (let i = 0; i < codeLength; i++) {
        const randomIndex = Math.floor(Math.random() * characters.length);
        verificationCode += characters[randomIndex];
    }

    return verificationCode;
};

// Ruta para manejar las preferencias durante el registro
router.post('/preferences', async (req, res) => {
    const { username, preferences } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Validar estructura de preferencias categorizadas
        if (!preferences || typeof preferences !== 'object') {
            return res.status(400).json({ message: 'Las preferencias deben ser un objeto con categorías' });
        }

        // Validar que cada categoría tenga subcategorías válidas
        const validStructure = {
            convivencia: ['hogar', 'social', 'mascotas'],
            gastronomia: ['habitos', 'bebidas', 'habilidades'],
            deporte: ['intensidad', 'menteCuerpo', 'deportesPelota', 'aguaNaturaleza'],
            entretenimiento: ['pantalla', 'musica', 'gaming'],
            creatividad: ['artesPlasticas', 'tecnologia', 'moda'],
            interesesSociales: ['causas', 'conocimiento']
        };

        // Validar y limpiar preferencias
        const cleanedPreferences = {};
        for (const [mainCat, subCats] of Object.entries(validStructure)) {
            if (preferences[mainCat]) {
                cleanedPreferences[mainCat] = {};
                for (const subCat of subCats) {
                    if (preferences[mainCat][subCat] && Array.isArray(preferences[mainCat][subCat])) {
                        // Limitar a 5 tags por subcategoría
                        cleanedPreferences[mainCat][subCat] = preferences[mainCat][subCat].slice(0, 5);
                    } else {
                        cleanedPreferences[mainCat][subCat] = [];
                    }
                }
            }
        }

        user.preferences = cleanedPreferences;
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

// POST /api/register/roommate-preferences
// Actualizar preferencias de roommate durante el registro
router.post('/roommate-preferences', async (req, res) => {
    const { username, gender, ageMin, ageMax } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Validaciones
        if (!gender || !['male', 'female', 'both'].includes(gender)) {
            return res.status(400).json({ message: 'Género inválido. Debe ser: male, female o both' });
        }

        if (ageMin !== undefined && ageMin !== null) {
            if (ageMin < 18 || ageMin > 100) {
                return res.status(400).json({ message: 'Edad mínima debe estar entre 18 y 100' });
            }
        }

        if (ageMax !== undefined && ageMax !== null) {
            if (ageMax < 18 || ageMax > 100) {
                return res.status(400).json({ message: 'Edad máxima debe estar entre 18 y 100' });
            }
        }

        if (ageMin && ageMax && ageMin > ageMax) {
            return res.status(400).json({ message: 'La edad mínima no puede ser mayor que la máxima' });
        }

        // Actualizar preferencias de roommate
        user.roommatePreferences = {
            gender: gender,
            ageMin: ageMin || 18,
            ageMax: ageMax || 100
        };

        await user.save();

        return res.json({ 
            message: 'Preferencias de roommate actualizadas exitosamente',
            roommatePreferences: user.roommatePreferences
        });
    } catch (error) {
        console.error('Error al actualizar preferencias de roommate:', error);
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

// Ruta para manejar hábitos de convivencia durante el registro
router.post('/living_habits', async (req, res) => {
    const { username, livingHabits, dealBreakers } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Actualizar hábitos de convivencia
        if (livingHabits) {
            user.livingHabits = {
                smoker: livingHabits.smoker || false,
                hasPets: livingHabits.hasPets || false,
                acceptsPets: livingHabits.acceptsPets || false,
                cleanliness: livingHabits.cleanliness || 'normal',
                noiseLevel: livingHabits.noiseLevel || 'normal',
                schedule: livingHabits.schedule || 'normal',
                socialLevel: livingHabits.socialLevel || 'friendly',
                hasGuests: livingHabits.hasGuests || false,
                drinker: livingHabits.drinker || 'social'
            };
        }

        // Actualizar deal breakers
        if (dealBreakers) {
            user.dealBreakers = {
                noSmokers: dealBreakers.noSmokers || false,
                noPets: dealBreakers.noPets || false,
                noParties: dealBreakers.noParties || false,
                noChildren: dealBreakers.noChildren || false
            };
        }

        await user.save();

        return res.json({ message: 'Hábitos de convivencia actualizados exitosamente' });
    } catch (error) {
        console.error('Error al actualizar hábitos de convivencia:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar información de vivienda durante el registro
router.post('/housing_info', async (req, res) => {
    const { username, housingInfo } = req.body;

    try {
        const user = await User.findOne({ username });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Actualizar información de vivienda
        if (housingInfo) {
            user.housingInfo = {
                budgetMin: housingInfo.budgetMin,
                budgetMax: housingInfo.budgetMax,
                preferredZones: housingInfo.preferredZones || [],
                hasPlace: housingInfo.hasPlace || false,
                moveInDate: housingInfo.moveInDate,
                stayDuration: housingInfo.stayDuration,
                city: housingInfo.city,
                generalZone: housingInfo.generalZone
            };
        }

        await user.save();

        return res.json({ message: 'Información de vivienda actualizada exitosamente' });
    } catch (error) {
        console.error('Error al actualizar información de vivienda:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Ruta para manejar la foto de perfil durante el registro
router.post('/profile_photo', upload.single('profilePhoto'), async (req, res) => {
    try {
        console.log('=== PROFILE PHOTO REQUEST ===');
        console.log('Body:', req.body);
        console.log('File:', req.file ? 'Present' : 'Missing');
        
        const { username, email } = req.body;
        if (!req.file) {
            console.log('ERROR: No se proporcionó ninguna imagen');
            return res.status(400).json({ message: 'No se proporcionó ninguna imagen' });
        }

        const user = await User.findOne({ username });

        if (!user) {
            console.log('ERROR: Usuario no encontrado:', username);
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Subir imagen a Cloudinary
        console.log('Subiendo imagen a Cloudinary...');
        const cloudinaryResult = await uploadImage(
            req.file.buffer, 
            'profile_photos', 
            `user_${username}`
        );
        
        // Guardar URL de Cloudinary en el usuario
        user.profilePhoto = cloudinaryResult.secure_url;
        user.profilePhotoPublicId = cloudinaryResult.public_id;
        await user.save();
        
        console.log('Imagen subida exitosamente a Cloudinary:', cloudinaryResult.secure_url);

        const verificationCode = generateVerificationCode();
        user.verificationCode = verificationCode;

        // Intentar enviar email, pero continuar si falla (modo testing)
        try {
            console.log('Enviando email a:', email);
            await sendVerificationEmail(email, verificationCode);
            console.log('Email enviado exitosamente');
        } catch (emailError) {
            console.warn('No se pudo enviar email de verificación (modo testing):', emailError.message);
            console.log('Marcando usuario como verificado automáticamente para continuar el registro');
            // En modo testing, marcar como verificado automáticamente
            user.isVerified = true;
        }

        await user.save();

        return res.json({ 
            message: 'Foto de perfil actualizada exitosamente',
            photoUrl: cloudinaryResult.secure_url,
            emailSent: user.isVerified ? false : true // Indicar si se envió el email
        });
    } catch (error) {
        console.error('Error al actualizar la foto de perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

router.post('/verify', async (req, res) => {
    const { email, verificationCode } = req.body;

    try {
        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }
        if (user.verificationCode !== verificationCode) {
            return res.status(400).json({ message: 'Código de verificación incorrecto' });
        }

        // Marcar al usuario como verificado (puedes agregar este campo en tu modelo de usuario)
        user.isVerified = true;
        await user.save();

        return res.json({ message: 'Código de verificación verificado exitosamente' });
    } catch (error) {
        console.error('Error al verificar el código de verificación:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

// Endpoint para registro completo con todos los datos a la vez
router.post('/complete', async (req, res) => {
    try {
        const {
            username,
            password,
            email,
            birthdate,
            preferences,
            roommatePreferences,
            livingHabits,
            dealBreakers,
            housingInfo,
            personalInfo,
            profilePhoto
        } = req.body;

        console.log('[REGISTRO COMPLETO] Iniciando registro para:', username);

        // Validar datos requeridos
        if (!username || !password || !email || !birthdate) {
            return res.status(400).json({ message: 'Faltan datos requeridos (username, password, email, birthdate)' });
        }

        // Verificar si el usuario ya existe
        const existingUser = await User.findOne({ $or: [{ username }, { email }] });
        if (existingUser) {
            return res.status(400).json({ message: 'El usuario o email ya existe' });
        }

        // Generar código de verificación
        const verificationCode = generateVerificationCode();

        // Hashear la contraseña
        const hashedPassword = await bcrypt.hash(password, 10);
        console.log('[REGISTRO COMPLETO] Contraseña hasheada');

        // Procesar foto de perfil si existe
        let profilePhotoUrl = null;
        if (profilePhoto) {
            try {
                console.log('[REGISTRO COMPLETO] Subiendo foto de perfil a Cloudinary...');
                const buffer = Buffer.from(profilePhoto, 'base64');
                const uploadResult = await uploadImage(buffer, username);
                profilePhotoUrl = uploadResult.secure_url; // Extraer solo la URL
                console.log('[REGISTRO COMPLETO] Foto subida:', profilePhotoUrl);
            } catch (photoError) {
                console.error('[REGISTRO COMPLETO] Error al subir foto:', photoError);
                // No bloquear el registro por error en foto
            }
        }

        // Mapear roommatePreferences (frontend usa minAge/maxAge, backend usa ageMin/ageMax)
        const mappedRoommatePreferences = roommatePreferences ? {
            gender: roommatePreferences.gender || 'both',
            ageMin: roommatePreferences.minAge !== undefined ? roommatePreferences.minAge : (roommatePreferences.ageMin !== undefined ? roommatePreferences.ageMin : 18),
            ageMax: roommatePreferences.maxAge !== undefined ? roommatePreferences.maxAge : (roommatePreferences.ageMax !== undefined ? roommatePreferences.ageMax : 99)
        } : { gender: 'both', ageMin: 18, ageMax: 99 };
        
        console.log('[REGISTRO] roommatePreferences recibidas:', roommatePreferences);
        console.log('[REGISTRO] roommatePreferences mapeadas:', mappedRoommatePreferences);

        // Crear el nuevo usuario con todos los datos
        const newUser = new User({
            username,
            password: hashedPassword,
            email,
            birthdate,
            gender: req.body.gender || undefined, // Género del usuario
            verificationCode,
            isVerified: false, // Se marcará como true si el email no es el del admin
            profilePhoto: profilePhotoUrl,
            preferences: preferences || {},
            roommatePreferences: mappedRoommatePreferences,
            livingHabits: livingHabits || {},
            dealBreakers: dealBreakers || {},
            housingInfo: housingInfo || {},
            personalInfo: {
                job: personalInfo?.job || '',
                religion: personalInfo?.religion || '',
                politicPreference: personalInfo?.politicPreferences || '',
                aboutMe: personalInfo?.aboutMe || ''
            }
        });

        // Intentar enviar email de verificación
        try {
            console.log('[REGISTRO COMPLETO] Intentando enviar email de verificación a:', email);
            await sendVerificationEmail(email, verificationCode);
            console.log('[REGISTRO COMPLETO] Email enviado exitosamente');
        } catch (emailError) {
            console.error('[REGISTRO COMPLETO] Error al enviar email, auto-verificando:', emailError);
            // Si falla el envío (no es el email del admin), auto-verificar
            if (email !== 'baralle2014@gmail.com') {
                newUser.isVerified = true;
                console.log('[REGISTRO COMPLETO] Usuario auto-verificado');
            }
        }

        await newUser.save();
        console.log('[REGISTRO COMPLETO] Usuario creado exitosamente:', username);

        return res.status(201).json({ 
            message: 'Registro completado exitosamente',
            username,
            isVerified: newUser.isVerified
        });

    } catch (error) {
        console.error('[REGISTRO COMPLETO] Error:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

module.exports = router;
