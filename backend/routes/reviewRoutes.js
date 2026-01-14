const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { verifyToken } = require('../middleware/auth');
const { isAdmin } = require('../middleware/isAdmin');

// Crear una nueva review (requiere autenticación)
router.post('/create', verifyToken, reviewController.createReview);

// Obtener reviews de un usuario específico (requiere autenticación para verificar premium)
router.get('/user/:username', verifyToken, reviewController.getReviewsForUser);

// Obtener estadísticas de reviews de un usuario
router.get('/stats/:username', reviewController.getReviewStats);

// Verificar si un usuario puede dejar review a otro
router.get('/can-leave', verifyToken, reviewController.canLeaveReview);

// ========== RUTAS DE ADMIN ==========

// Obtener reviews pendientes de moderación (solo admin)
router.get('/pending', verifyToken, isAdmin, reviewController.getPendingReviews);

// Moderar una review (aprobar/rechazar) (solo admin)
router.put('/moderate/:reviewId', verifyToken, isAdmin, reviewController.moderateReview);

module.exports = router;
