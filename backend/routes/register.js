const express = require('express');
const { Resend } = require('resend');
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
        const profilePhoto = req.file.buffer;

        const user = await User.findOne({ username });

        if (!user) {
            console.log('ERROR: Usuario no encontrado:', username);
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        user.profilePhoto = profilePhoto;
        await user.save();

        const verificationCode = generateVerificationCode();
        user.verificationCode = verificationCode;
        await user.save();

        console.log('Enviando email a:', email);
        await sendVerificationEmail(email, verificationCode);
        console.log('Email enviado exitosamente');

        return res.json({ message: 'Foto de perfil actualizada exitosamente' });
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

module.exports = router;
