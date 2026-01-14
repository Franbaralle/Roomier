const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  // Usuario que DEJA la review (debe tener hasPlace=false)
  reviewer: {
    type: String,
    required: true,
    ref: 'User'
  },
  
  // Usuario que RECIBE la review (debe tener hasPlace=true)
  reviewed: {
    type: String,
    required: true,
    ref: 'User'
  },
  
  // Rating general (1-5)
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  
  // Ratings por categoría (1-5 cada uno)
  categories: {
    cleanliness: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    communication: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    accuracy: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    },
    location: {
      type: Number,
      required: true,
      min: 1,
      max: 5
    }
  },
  
  // Comentario de la review
  comment: {
    type: String,
    required: true,
    maxlength: 1000
  },
  
  // Estado de moderación
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  
  // Razón de rechazo (si aplica)
  moderationNote: {
    type: String,
    default: null
  },
  
  // Verificada (si realmente vivieron juntos - futuro)
  verified: {
    type: Boolean,
    default: false
  },
  
  // Fecha de creación
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  // Fecha de aprobación/rechazo
  moderatedAt: {
    type: Date,
    default: null
  },
  
  // Admin que moderó
  moderatedBy: {
    type: String,
    default: null
  }
});

// Índices para queries rápidos
reviewSchema.index({ reviewed: 1, status: 1 });
reviewSchema.index({ reviewer: 1 });
reviewSchema.index({ createdAt: -1 });

// Índice compuesto para evitar reviews duplicadas
reviewSchema.index({ reviewer: 1, reviewed: 1 }, { unique: true });

module.exports = mongoose.model('Review', reviewSchema);
