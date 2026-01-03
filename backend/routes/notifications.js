const express = require('express');
const router = express.Router();
const User = require('../models/User');
const logger = require('../utils/logger');

/**
 * Guardar o actualizar el token FCM de un usuario
 * POST /api/notifications/token
 */
router.post('/token', async (req, res) => {
  try {
    const { username, fcmToken } = req.body;

    if (!username || !fcmToken) {
      return res.status(400).json({ 
        success: false, 
        message: 'Username y fcmToken son requeridos' 
      });
    }

    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'Usuario no encontrado' 
      });
    }

    // Actualizar el token FCM
    user.fcmToken = fcmToken;
    user.lastActive = new Date();
    await user.save();

    logger.info(`Token FCM actualizado para usuario: ${username}`);

    res.status(200).json({ 
      success: true, 
      message: 'Token FCM guardado correctamente' 
    });
  } catch (error) {
    logger.error(`Error guardando token FCM: ${error.message}`);
    res.status(500).json({ 
      success: false, 
      message: 'Error interno del servidor' 
    });
  }
});

/**
 * Eliminar el token FCM de un usuario (logout)
 * DELETE /api/notifications/token/:username
 */
router.delete('/token/:username', async (req, res) => {
  try {
    const { username } = req.params;

    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'Usuario no encontrado' 
      });
    }

    user.fcmToken = null;
    await user.save();

    logger.info(`Token FCM eliminado para usuario: ${username}`);

    res.status(200).json({ 
      success: true, 
      message: 'Token FCM eliminado correctamente' 
    });
  } catch (error) {
    logger.error(`Error eliminando token FCM: ${error.message}`);
    res.status(500).json({ 
      success: false, 
      message: 'Error interno del servidor' 
    });
  }
});

module.exports = router;
