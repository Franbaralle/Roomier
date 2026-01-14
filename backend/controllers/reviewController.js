const Review = require('../models/Review');
const User = require('../models/user');
const Chat = require('../models/chatModel');

// Crear una nueva review
exports.createReview = async (req, res) => {
  try {
    const { reviewer, reviewed, rating, categories, comment } = req.body;

    // Validar que todos los campos estén presentes
    if (!reviewer || !reviewed || !rating || !categories || !comment) {
      return res.status(400).json({ error: 'Todos los campos son requeridos' });
    }

    // Validar rating general
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating debe estar entre 1 y 5' });
    }

    // Validar ratings por categoría
    const { cleanliness, communication, accuracy, location } = categories;
    if (!cleanliness || !communication || !accuracy || !location) {
      return res.status(400).json({ error: 'Todas las categorías son requeridas' });
    }

    if ([cleanliness, communication, accuracy, location].some(r => r < 1 || r > 5)) {
      return res.status(400).json({ error: 'Todos los ratings deben estar entre 1 y 5' });
    }

    // Obtener usuarios
    const reviewerUser = await User.findOne({ username: reviewer });
    const reviewedUser = await User.findOne({ username: reviewed });

    if (!reviewerUser || !reviewedUser) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    // Verificar que el reviewer NO tiene lugar (hasPlace=false)
    if (reviewerUser.hasPlace === true) {
      return res.status(403).json({ 
        error: 'Solo usuarios que buscan lugar pueden dejar reviews' 
      });
    }

    // Verificar que el reviewed SÍ tiene lugar (hasPlace=true)
    if (reviewedUser.hasPlace === false) {
      return res.status(403).json({ 
        error: 'Solo se pueden dejar reviews a usuarios que tienen lugar' 
      });
    }

    // Verificar que tuvieron match mutuo
    const hadMatch = reviewerUser.isMatch && 
                     reviewerUser.isMatch.includes(reviewed);

    if (!hadMatch) {
      return res.status(403).json({ 
        error: 'Solo puedes dejar reviews a usuarios con los que tuviste match mutuo' 
      });
    }

    // Verificar que no existe una review previa
    const existingReview = await Review.findOne({ reviewer, reviewed });
    if (existingReview) {
      return res.status(400).json({ 
        error: 'Ya has dejado una review para este usuario' 
      });
    }

    // Crear la review
    const newReview = new Review({
      reviewer,
      reviewed,
      rating,
      categories: {
        cleanliness,
        communication,
        accuracy,
        location
      },
      comment,
      status: 'pending' // Requiere moderación
    });

    await newReview.save();

    res.status(201).json({ 
      message: 'Review creada exitosamente. Será visible una vez aprobada por moderación.',
      review: newReview 
    });

  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({ error: 'Error al crear la review' });
  }
};

// Obtener reviews de un usuario (solo aprobadas)
// NOTA: El frontend debe verificar isPremium para mostrar o no
exports.getReviewsForUser = async (req, res) => {
  try {
    const { username } = req.params;
    const { requesterUsername } = req.query; // Quién solicita verlas

    // Verificar que el usuario existe
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    // Verificar que el usuario tiene lugar
    if (!user.hasPlace) {
      return res.status(400).json({ 
        error: 'Este usuario no tiene lugar, no puede recibir reviews' 
      });
    }

    // Obtener el usuario que solicita (para verificar premium)
    const requester = await User.findOne({ username: requesterUsername });
    if (!requester) {
      return res.status(404).json({ error: 'Usuario solicitante no encontrado' });
    }

    // Obtener reviews aprobadas
    const reviews = await Review.find({ 
      reviewed: username, 
      status: 'approved' 
    })
    .select('reviewer rating categories comment createdAt verified')
    .sort({ createdAt: -1 });

    // Si el solicitante NO es premium y NO tiene lugar (busca lugar)
    // devolver reviews pero con flag para que el frontend las bluree
    const canViewReviews = requester.isPremium || requester.hasPlace || requester.username === username;

    res.json({ 
      reviews,
      canViewReviews, // Frontend usa esto para decidir si mostrar o blurear
      reviewCount: reviews.length
    });

  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ error: 'Error al obtener reviews' });
  }
};

// Obtener estadísticas de reviews de un usuario
exports.getReviewStats = async (req, res) => {
  try {
    const { username } = req.params;

    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    if (!user.hasPlace) {
      return res.status(400).json({ 
        error: 'Este usuario no tiene lugar' 
      });
    }

    // Obtener todas las reviews aprobadas
    const reviews = await Review.find({ 
      reviewed: username, 
      status: 'approved' 
    });

    if (reviews.length === 0) {
      return res.json({
        reviewCount: 0,
        averageRating: 0,
        categoryAverages: {
          cleanliness: 0,
          communication: 0,
          accuracy: 0,
          location: 0
        }
      });
    }

    // Calcular promedios
    const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = (totalRating / reviews.length).toFixed(1);

    const categoryTotals = {
      cleanliness: 0,
      communication: 0,
      accuracy: 0,
      location: 0
    };

    reviews.forEach(review => {
      categoryTotals.cleanliness += review.categories.cleanliness;
      categoryTotals.communication += review.categories.communication;
      categoryTotals.accuracy += review.categories.accuracy;
      categoryTotals.location += review.categories.location;
    });

    const categoryAverages = {
      cleanliness: (categoryTotals.cleanliness / reviews.length).toFixed(1),
      communication: (categoryTotals.communication / reviews.length).toFixed(1),
      accuracy: (categoryTotals.accuracy / reviews.length).toFixed(1),
      location: (categoryTotals.location / reviews.length).toFixed(1)
    };

    res.json({
      reviewCount: reviews.length,
      averageRating: parseFloat(averageRating),
      categoryAverages: {
        cleanliness: parseFloat(categoryAverages.cleanliness),
        communication: parseFloat(categoryAverages.communication),
        accuracy: parseFloat(categoryAverages.accuracy),
        location: parseFloat(categoryAverages.location)
      }
    });

  } catch (error) {
    console.error('Error fetching review stats:', error);
    res.status(500).json({ error: 'Error al obtener estadísticas' });
  }
};

// ADMIN: Obtener todas las reviews pendientes de moderación
exports.getPendingReviews = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const reviews = await Review.find({ status: 'pending' })
      .populate('reviewer', 'username profilePhoto')
      .populate('reviewed', 'username profilePhoto')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Review.countDocuments({ status: 'pending' });

    res.json({
      reviews,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      total: count
    });

  } catch (error) {
    console.error('Error fetching pending reviews:', error);
    res.status(500).json({ error: 'Error al obtener reviews pendientes' });
  }
};

// ADMIN: Moderar una review (aprobar/rechazar)
exports.moderateReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { action, moderationNote, moderatedBy } = req.body; // action: 'approve' o 'reject'

    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({ error: 'Acción inválida' });
    }

    const review = await Review.findById(reviewId);
    if (!review) {
      return res.status(404).json({ error: 'Review no encontrada' });
    }

    review.status = action === 'approve' ? 'approved' : 'rejected';
    review.moderatedAt = new Date();
    review.moderatedBy = moderatedBy;
    if (moderationNote) {
      review.moderationNote = moderationNote;
    }

    await review.save();

    res.json({ 
      message: `Review ${action === 'approve' ? 'aprobada' : 'rechazada'} exitosamente`,
      review 
    });

  } catch (error) {
    console.error('Error moderating review:', error);
    res.status(500).json({ error: 'Error al moderar review' });
  }
};

// Verificar si un usuario puede dejar review a otro
exports.canLeaveReview = async (req, res) => {
  try {
    const { reviewer, reviewed } = req.query;

    if (!reviewer || !reviewed) {
      return res.status(400).json({ error: 'Parámetros faltantes' });
    }

    // Obtener usuarios
    const reviewerUser = await User.findOne({ username: reviewer });
    const reviewedUser = await User.findOne({ username: reviewed });

    if (!reviewerUser || !reviewedUser) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    // Verificar permisos básicos
    if (reviewerUser.hasPlace === true) {
      return res.json({ 
        canLeave: false, 
        reason: 'Solo usuarios que buscan lugar pueden dejar reviews' 
      });
    }

    if (reviewedUser.hasPlace === false) {
      return res.json({ 
        canLeave: false, 
        reason: 'Solo se pueden dejar reviews a usuarios con lugar' 
      });
    }

    // Verificar match mutuo
    const hadMatch = reviewerUser.isMatch && 
                     reviewerUser.isMatch.includes(reviewed);

    if (!hadMatch) {
      return res.json({ 
        canLeave: false, 
        reason: 'Solo puedes dejar reviews a usuarios con los que tuviste match' 
      });
    }

    // Verificar si ya dejó review
    const existingReview = await Review.findOne({ reviewer, reviewed });
    if (existingReview) {
      return res.json({ 
        canLeave: false, 
        reason: 'Ya has dejado una review para este usuario',
        existingReview: {
          status: existingReview.status,
          rating: existingReview.rating
        }
      });
    }

    res.json({ canLeave: true });

  } catch (error) {
    console.error('Error checking review permissions:', error);
    res.status(500).json({ error: 'Error al verificar permisos' });
  }
};
