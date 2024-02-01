const express = require('express');
const nodemailer = require('nodemailer');
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
        // Configuración del servicio de envío de correos electrónicos (usando nodemailer)
        const transporter = nodemailer.createTransport({
            service: 'gmail', // Puedes cambiarlo según tu proveedor de correo
            auth: {
                user: 'roomier2024@gmail.com',
                pass: 'uyaw gmlh jpto enbr',
            },
        });

        // Contenido del correo electrónico
        const mailOptions = {
            from: 'roomier2024@gmail.com', // Remitente
            to, // Destinatario
            subject: 'Confirmación de Registro', // Asunto del correo
            text: `Tu código de verificación es: ${verificationCode}`, // Cuerpo del correo
        };

        // Envío del correo electrónico
        await transporter.sendMail(mailOptions);
    } catch (error) {
        console.error('Error al enviar el correo electrónico de verificación:', error);
        // Puedes manejar el error según tus necesidades (por ejemplo, almacenarlo en un registro de errores)
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

// Ruta para manejar la foto de perfil durante el registro
router.post('/profile_photo', upload.single('profilePhoto'), async (req, res) => {
    try {
        const { username, email } = req.body;
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

        const verificationCode = generateVerificationCode();
        user.verificationCode = verificationCode;
        await user.save();

        await sendVerificationEmail(email, verificationCode);

        return res.json({ message: 'Foto de perfil actualizada exitosamente' });
    } catch (error) {
        console.error('Error al actualizar la foto de perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor' });
    }
});

router.post('/verify', async (req, res) => {
    console.log('Ruta de verificación alcanzada');
    const {email, verificationCode } = req.body;

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
