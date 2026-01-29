const mongoose = require('mongoose');

/**
 * Modelo para almacenar barrios sugeridos por usuarios
 * Estos barrios provienen de ciudades donde no tenemos data cargada
 * Permite análisis posterior para decidir qué barrios agregar
 */
const suggestedNeighborhoodSchema = new mongoose.Schema({
  // Nombre del barrio sugerido
  name: {
    type: String,
    required: true,
    trim: true
  },
  
  // Información de ubicación
  cityId: {
    type: String,
    required: true,
    index: true // Para búsquedas rápidas por ciudad
  },
  
  cityName: {
    type: String,
    required: true
  },
  
  provinceName: {
    type: String,
    required: true
  },
  
  // Metadata del usuario
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false // Opcional si el usuario aún no está registrado
  },
  
  userEmail: {
    type: String,
    required: false
  },
  
  // Contador de cuántas veces ha sido sugerido
  suggestionCount: {
    type: Number,
    default: 1
  },
  
  // Lista de usuarios que lo sugirieron (para evitar duplicados)
  suggestedBy: [{
    userId: mongoose.Schema.Types.ObjectId,
    email: String,
    date: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Estado de revisión
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'duplicate'],
    default: 'pending'
  },
  
  // Notas del administrador
  adminNotes: {
    type: String,
    default: ''
  },
  
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Índice compuesto para evitar duplicados y acelerar búsquedas
suggestedNeighborhoodSchema.index({ cityId: 1, name: 1 });
suggestedNeighborhoodSchema.index({ status: 1 });
suggestedNeighborhoodSchema.index({ suggestionCount: -1 });

// Middleware para actualizar updatedAt
suggestedNeighborhoodSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('SuggestedNeighborhood', suggestedNeighborhoodSchema);
