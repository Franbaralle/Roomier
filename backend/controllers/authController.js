// authController.js
const express = require('express');
const router = express.Router();
const User = require('../models/user');
const TokenBlacklist = require('../models/TokenBlacklist');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { jwtSecret, jwtExpiration, bcryptSaltRounds } = require('../config/security');
const { loginLimiter, registerLimiter, passwordResetLimiter } = require('../middleware/rateLimiter');
const { verifyToken } = require('../middleware/auth');

// Ruta para el registro de usuarios
router.post('/register', registerLimiter, async (req, res) => {
  try {
    console.log('=== REGISTER REQUEST ===');
    console.log('Body:', JSON.stringify(req.body));
    
    const { username, password, email, birthdate } = req.body;

    // Verificar si el usuario ya existe
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      console.log('ERROR: El usuario ya existe:', username);
      return res.status(400).json({ error: 'El usuario ya existe' });
    }

    // Hashear la contraseña antes de guardarla
    const hashedPassword = await bcrypt.hash(password, bcryptSaltRounds);

    // Crear un nuevo usuario
    const newUser = new User({ username, password: hashedPassword, email, birthdate });
    await newUser.save();
    console.log('Usuario creado exitosamente:', username);

    // Generar token JWT para el nuevo usuario
    const token = jwt.sign({ username: newUser.username, userId: newUser._id }, jwtSecret, { expiresIn: jwtExpiration });

    res.status(201).json({ 
      message: 'Usuario registrado exitosamente',
      token,
      username: newUser.username
    });
  } catch (error) {
    console.error('ERROR EN REGISTRO:', error);
    res.status(500).json({ error: 'Error en el servidor' });
  }
});

// Ruta para el inicio de sesión
router.post('/login', loginLimiter, async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validar que se enviaron los campos requeridos
    if (!username || !password) {
      return res.status(400).json({ error: 'Usuario y contraseña son requeridos' });
    }

    // Buscar al usuario por nombre de usuario (case-insensitive)
    const user = await User.findOne({ 
      username: { $regex: new RegExp(`^${username}$`, 'i') } 
    });

    if (!user) {
      console.log(`Intento de login fallido: usuario "${username}" no encontrado`);
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
    }

    // Verificar estado de la cuenta
    if (user.accountStatus === 'suspended') {
      const now = new Date();
      if (user.suspendedUntil && user.suspendedUntil > now) {
        return res.status(403).json({ 
          error: 'Cuenta suspendida',
          message: `Tu cuenta está suspendida hasta ${user.suspendedUntil.toLocaleDateString()}`,
          suspendedUntil: user.suspendedUntil
        });
      } else {
        // Si la suspensión expiró, reactivar cuenta
        user.accountStatus = 'active';
        user.suspendedUntil = null;
        await user.save();
      }
    }

    if (user.accountStatus === 'banned') {
      return res.status(403).json({ 
        error: 'Cuenta bloqueada',
        message: 'Tu cuenta ha sido bloqueada permanentemente',
        reason: user.banReason
      });
    }

    // Verificar si la contraseña es válida
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      console.log(`Intento de login fallido: contraseña incorrecta para usuario "${username}"`);
      return res.status(401).json({ error: 'Usuario o contraseña incorrectos' });
    }

    // Actualizar última actividad
    user.lastActive = new Date();
    await user.save();

    const token = jwt.sign({ username: user.username, userId: user._id }, jwtSecret, { expiresIn: jwtExpiration });

    console.log(`Login exitoso: usuario "${username}"`);

    res.status(200).json({ 
      message: 'Inicio de sesión exitoso', 
      token,
      username: user.username,
      email: user.email,
      isAdmin: user.isAdmin || false
    });
  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Ruta para actualizar la contraseña (usa email para mayor seguridad)
router.put('/update-password', passwordResetLimiter, async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    // Validar que se proporcionen los datos necesarios
    if (!email || !newPassword) {
      return res.status(400).json({ message: 'Email y nueva contraseña son requeridos' });
    }

    // Buscar usuario por email (más seguro que username)
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      return res.status(404).json({ message: 'No se encontró una cuenta con ese email' });
    }

    // Validar que la contraseña tenga al menos 6 caracteres
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'La contraseña debe tener al menos 6 caracteres' });
    }

    // Hashear la nueva contraseña antes de guardarla
    const hashedPassword = await bcrypt.hash(newPassword, bcryptSaltRounds);
    user.password = hashedPassword;

    await user.save();

    logger.info(`Contraseña actualizada para usuario: ${user.username} (email: ${email})`);

    return res.status(200).json({ message: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    logger.error('Error al restablecer la contraseña:', error);
    return res.status(500).json({ message: 'Error interno del servidor' });
  }
});

// Ruta para cerrar sesión (logout) - agregar token a blacklist
router.post('/logout', verifyToken, async (req, res) => {
  try {
    const token = req.token;
    const username = req.username;

    // Decodificar el token para obtener la fecha de expiración
    const decoded = jwt.decode(token);
    const expiresAt = new Date(decoded.exp * 1000);

    // Agregar el token a la blacklist
    await TokenBlacklist.create({
      token,
      username,
      reason: 'logout',
      expiresAt
    });

    console.log(`Logout exitoso: usuario "${username}" - token agregado a blacklist`);

    res.status(200).json({ 
      message: 'Sesión cerrada exitosamente',
      success: true
    });
  } catch (error) {
    console.error('Error en logout:', error);
    // Si ya existe en blacklist (por ejemplo, doble logout), es OK
    if (error.code === 11000) {
      return res.status(200).json({ 
        message: 'Sesión ya cerrada',
        success: true
      });
    }
    res.status(500).json({ error: 'Error al cerrar sesión' });
  }
});

// Ruta para eliminar cuenta
router.delete('/delete/:username', async (req, res) => {
  const { username } = req.params;

  try {
    // Buscar al usuario por nombre de usuario
    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Eliminar al usuario de la base de datos
    await User.deleteOne({ username });

    return res.json({ message: 'Cuenta eliminada exitosamente' });
  } catch (error) {
    console.error('Error al eliminar la cuenta:', error);
    return res.status(500).json({ message: 'Error interno del servidor' });
  }
});

// Ruta para exportar datos del usuario (Ley 25.326 Art. 14 - Derecho de Acceso)
router.get('/export/:username', verifyToken, async (req, res) => {
  const { username } = req.params;

  try {
    // Verificar que el usuario solicita sus propios datos
    if (req.username !== username) {
      return res.status(403).json({ 
        message: 'No autorizado: solo puedes exportar tus propios datos' 
      });
    }

    // Buscar al usuario con todos sus datos
    const user = await User.findOne({ username }).lean();

    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Eliminar campos sensibles/internos que no deben exportarse
    delete user.password; // Nunca exportar contraseña (aunque esté hasheada)
    delete user.__v; // Campo interno de Mongoose
    delete user.verificationCode; // Código temporal de verificación
    
    // Preparar datos para exportación
    const exportData = {
      // Metadata de exportación
      exportDate: new Date().toISOString(),
      exportedBy: username,
      dataProtectionNotice: 'Datos exportados según Ley 25.326 de Protección de Datos Personales de Argentina',
      
      // Datos del usuario
      userData: {
        // Información básica
        username: user.username,
        email: user.email,
        createdAt: user.createdAt,
        dateOfBirth: user.dateOfBirth,
        gender: user.gender,
        
        // Información personal
        personalInfo: user.personalInfo,
        
        // Intereses
        preferences: user.preferences,
        
        // Hábitos de convivencia
        livingHabits: user.livingHabits,
        dealBreakers: user.dealBreakers,
        
        // Información de vivienda
        housingInfo: user.housingInfo,
        hasPlace: user.hasPlace,
        
        // Fotos (URLs)
        profilePhotos: user.profilePhotos,
        homePhotos: user.homePhotos,
        
        // Verificación
        verification: user.verification,
        
        // Estadísticas
        isMatch: user.isMatch || [],
        notMatch: user.notMatch || [],
        blockedUsers: user.blockedUsers || [],
        reportedBy: user.reportedBy || [],
        
        // Información revelada
        revealedInfo: user.revealedInfo || [],
        
        // Estado de cuenta
        accountStatus: user.accountStatus,
        isPremium: user.isPremium,
        isAdmin: user.isAdmin,
        
        // First Steps
        firstStepsRemaining: user.firstStepsRemaining,
        firstStepsUsedThisWeek: user.firstStepsUsedThisWeek,
        firstStepsResetDate: user.firstStepsResetDate,
      }
    };

    // Registrar la exportación en logs (auditoría)
    console.log(`[EXPORT] Usuario ${username} exportó sus datos - ${new Date().toISOString()}`);

    // Enviar como JSON descargable
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Content-Disposition', `attachment; filename="roomier-datos-${username}-${Date.now()}.json"`);
    
    return res.json(exportData);
  } catch (error) {
    console.error('Error al exportar datos:', error);
    return res.status(500).json({ message: 'Error interno del servidor' });
  }
});

module.exports = router;