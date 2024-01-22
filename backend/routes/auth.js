const express = require('express');
const router = express.Router();
const User = require('../models/user');
const bcrypt = require('bcrypt');

router.get('/', (req, res) => {
  res.send('¡Hola, mundo!');
});

router.post('/register', async (req, res) => {
  try {
    const { username, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, password: hashedPassword });
    await user.save();
    res.status(201).json({ message: 'User registered successfully.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password.' });
    }
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid username or password.' });
    }
    res.status(200).json({ message: 'Login successful.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

router.put('/update-password/:username', async (req, res) => {
  const { username } = req.params;
  const { newPassword } = req.body;
  console.log(username);
  console.log(newPassword);

  try {
    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    user.password = newPassword;

    await user.save();

    return res.json({ message: 'Contraseña actualizada exitosamente' });
  } catch (error) {
    console.error('Error al actualizar la contraseña:', error);
    return res.status(500).json({ message: 'Error interno del servidor' });
  }
});

module.exports = router;