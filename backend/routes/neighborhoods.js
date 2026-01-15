const express = require('express');
const router = express.Router();
const Neighborhood = require('../models/neighborhood');

/**
 * GET /api/neighborhoods
 * Obtiene los barrios de una ciudad específica
 * Query params:
 *   - cityId: ID de Georef de la ciudad (requerido)
 *   - search: término de búsqueda opcional para filtrar barrios
 */
router.get('/', async (req, res) => {
  try {
    const { cityId, search } = req.query;

    if (!cityId) {
      return res.status(400).json({ 
        error: 'El parámetro cityId es requerido' 
      });
    }

    // Construir query base
    const query = { cityId };

    // Si hay término de búsqueda, agregarlo
    if (search && search.trim() !== '') {
      query.name = { 
        $regex: search.trim(), 
        $options: 'i' // Case insensitive
      };
    }

    // Buscar barrios ordenados alfabéticamente
    const neighborhoods = await Neighborhood
      .find(query)
      .select('name cityName provinceName') // Solo campos necesarios
      .sort({ name: 1 })
      .lean();

    res.json({
      count: neighborhoods.length,
      data: neighborhoods
    });

  } catch (error) {
    console.error('Error al obtener barrios:', error);
    res.status(500).json({ 
      error: 'Error al obtener barrios',
      message: error.message 
    });
  }
});

/**
 * GET /api/neighborhoods/stats
 * Obtiene estadísticas de barrios cargados por ciudad
 */
router.get('/stats', async (req, res) => {
  try {
    const stats = await Neighborhood.aggregate([
      {
        $group: {
          _id: {
            cityId: '$cityId',
            cityName: '$cityName',
            provinceName: '$provinceName'
          },
          count: { $sum: 1 }
        }
      },
      {
        $sort: { count: -1 }
      },
      {
        $project: {
          _id: 0,
          cityId: '$_id.cityId',
          cityName: '$_id.cityName',
          provinceName: '$_id.provinceName',
          neighborhoodsCount: '$count'
        }
      }
    ]);

    res.json({
      totalCities: stats.length,
      cities: stats
    });

  } catch (error) {
    console.error('Error al obtener estadísticas:', error);
    res.status(500).json({ 
      error: 'Error al obtener estadísticas',
      message: error.message 
    });
  }
});

module.exports = router;
