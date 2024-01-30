// authController.js
const express = require('express');
const router = express.Router();
const User = require('../models/user');
const bcrypt = require('bcrypt');

// Ruta para el registro de usuarios
router.post('/register', async (req, res) => {
  try {
    const { username, password, email, birthdate } = req.body;

    // Verificar si el usuario ya existe
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ error: 'El usuario ya existe' });
    }

    // Hashear la contraseña antes de guardarla
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear un nuevo usuario
    const newUser = new User({ username, password: hashedPassword, email, birthdate });
    await newUser.save();

    res.status(201).json({ message: 'Usuario registrado exitosamente' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error en el servidor' });
  }
});

// Ruta para el inicio de sesión
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Buscar al usuario por nombre de usuario
    const user = await User.findOne({ username });

    if (!user) {
      return res.status(401).json({ error: 'Usuario o contraseña inválidos' });
    }

    // Verificar si la contraseña es válida
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      return res.status(401).json({ error: 'Usuario o contraseña inválidos' });
    }

    res.status(200).json({ message: 'Inicio de sesión exitoso' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
});

// Ruta para actualizar la contraseña
router.put('/update-password/:username', async (req, res) => {
  const { username } = req.params;
  const { newPassword } = req.body;

  try {
    // Lógica para validar al usuario
    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Hashear la nueva contraseña antes de guardarla
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;

    await user.save();

    return res.status(200).json({ message: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    console.error('Error al restablecer la contraseña:', error);
    return res.status(500).json({ message: 'Error interno del servidor' });
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

module.exports = router;