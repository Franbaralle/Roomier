const mongoose = require('mongoose');

const neighborhoodSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  cityId: {
    type: String, // ID de Georef para la ciudad
    required: true,
    index: true
  },
  cityName: {
    type: String, // Nombre de la ciudad para búsquedas más fáciles
    required: true
  },
  provinceName: {
    type: String, // Nombre de la provincia
    required: true
  },
  geometry: {
    type: {
      type: String,
      enum: ['Polygon', 'MultiPolygon', 'Point'], // Agregado Point para barrios sin geometría detallada
      required: true
    },
    coordinates: {
      type: Array,
      required: true
    }
  },
  osmId: {
    type: String, // ID de OpenStreetMap para referencia
    unique: true,
    sparse: true
  },
  source: {
    type: String,
    enum: ['osm', 'official', 'manual'],
    default: 'osm'
  }
}, {
  timestamps: true
});

// Índice geoespacial para búsquedas de proximidad
neighborhoodSchema.index({ geometry: '2dsphere' });

// Índice compuesto para búsquedas por ciudad
neighborhoodSchema.index({ cityId: 1, name: 1 });

const Neighborhood = mongoose.model('Neighborhood', neighborhoodSchema);

module.exports = Neighborhood;
