const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { verifyToken } = require('../middleware/auth');
const User = require('../models/user');

// Middleware para verificar si el usuario es admin
const isAdmin = async (req, res, next) => {
  try {
    const user = await User.findOne({ username: req.user.username });
    if (!user || !user.isAdmin) {
      return res.status(403).json({ message: 'Acceso denegado. Se requieren permisos de administrador.' });
    }
    next();
  } catch (error) {
    res.status(500).json({ message: 'Error al verificar permisos', error: error.message });
  }
};

// Trackear evento (requiere autenticación)
router.post('/track', verifyToken, analyticsController.trackEvent);

// Obtener estadísticas del usuario actual
router.get('/my-stats', verifyToken, analyticsController.getUserStats);

// Obtener estadísticas globales (solo admin)
router.get('/global-stats', verifyToken, isAdmin, analyticsController.getGlobalStats);

// Obtener eventos recientes (solo admin)
router.get('/recent-events', verifyToken, isAdmin, analyticsController.getRecentEvents);

module.exports = router;
