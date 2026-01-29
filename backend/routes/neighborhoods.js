const express = require('express');
const router = express.Router();
const Neighborhood = require('../models/neighborhood');
const SuggestedNeighborhood = require('../models/suggestedNeighborhood');

/**
 * POST /api/neighborhoods/suggest
 * Guarda barrios sugeridos por usuarios para ciudades sin data
 * Body:
 *   - neighborhoods: array de strings con nombres de barrios
 *   - cityId: ID de Georef de la ciudad
 *   - cityName: nombre de la ciudad
 *   - provinceName: nombre de la provincia
 *   - userId: (opcional) ID del usuario
 *   - userEmail: (opcional) email del usuario
 */
router.post('/suggest', async (req, res) => {
  try {
    const { neighborhoods, cityId, cityName, provinceName, userId, userEmail } = req.body;

    if (!neighborhoods || !Array.isArray(neighborhoods) || neighborhoods.length === 0) {
      return res.status(400).json({ 
        error: 'El campo neighborhoods es requerido y debe ser un array' 
      });
    }

    if (!cityId || !cityName || !provinceName) {
      return res.status(400).json({ 
        error: 'Los campos cityId, cityName y provinceName son requeridos' 
      });
    }

    const savedSuggestions = [];
    const errors = [];

    for (const neighborhoodName of neighborhoods) {
      try {
        const trimmedName = neighborhoodName.trim();
        
        if (!trimmedName) continue;

        // Buscar si ya existe esta sugerencia
        let suggestion = await SuggestedNeighborhood.findOne({
          cityId,
          name: { $regex: new RegExp(`^${trimmedName}$`, 'i') } // Case insensitive
        });

        if (suggestion) {
          // Ya existe, incrementar contador si no fue sugerido por este usuario
          const alreadySuggestedByUser = suggestion.suggestedBy.some(
            s => s.userId?.toString() === userId?.toString() || s.email === userEmail
          );

          if (!alreadySuggestedByUser) {
            suggestion.suggestionCount += 1;
            suggestion.suggestedBy.push({
              userId,
              email: userEmail,
              date: new Date()
            });
            await suggestion.save();
            savedSuggestions.push(suggestion);
          } else {
            savedSuggestions.push(suggestion); // Ya lo había sugerido este usuario
          }
        } else {
          // Nueva sugerencia
          suggestion = new SuggestedNeighborhood({
            name: trimmedName,
            cityId,
            cityName,
            provinceName,
            userId,
            userEmail,
            suggestionCount: 1,
            suggestedBy: [{
              userId,
              email: userEmail,
              date: new Date()
            }]
          });

          await suggestion.save();
          savedSuggestions.push(suggestion);
        }
      } catch (err) {
        errors.push({ neighborhood: neighborhoodName, error: err.message });
      }
    }

    console.log(`✅ ${savedSuggestions.length} barrios sugeridos guardados para ${cityName}`);

    res.json({
      success: true,
      saved: savedSuggestions.length,
      errors: errors.length > 0 ? errors : undefined,
      message: `${savedSuggestions.length} barrios procesados correctamente`
    });

  } catch (error) {
    console.error('Error al guardar barrios sugeridos:', error);
    res.status(500).json({ 
      error: 'Error al guardar barrios sugeridos',
      message: error.message 
    });
  }
});

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

/**
 * GET /api/neighborhoods/suggestions
 * Obtiene barrios sugeridos por usuarios (para administradores)
 * Query params:
 *   - cityId: filtrar por ciudad (opcional)
 *   - status: filtrar por estado (pending/approved/rejected) (opcional)
 *   - minCount: mínimo de sugerencias para aparecer (opcional)
 */
router.get('/suggestions', async (req, res) => {
  try {
    const { cityId, status, minCount } = req.query;

    // Construir query
    const query = {};
    if (cityId) query.cityId = cityId;
    if (status) query.status = status;
    if (minCount) query.suggestionCount = { $gte: parseInt(minCount) };

    const suggestions = await SuggestedNeighborhood
      .find(query)
      .sort({ suggestionCount: -1, createdAt: -1 })
      .lean();

    // Agrupar por ciudad
    const byCity = suggestions.reduce((acc, sugg) => {
      const key = `${sugg.cityName}, ${sugg.provinceName}`;
      if (!acc[key]) {
        acc[key] = {
          cityId: sugg.cityId,
          cityName: sugg.cityName,
          provinceName: sugg.provinceName,
          suggestions: []
        };
      }
      acc[key].suggestions.push({
        name: sugg.name,
        count: sugg.suggestionCount,
        status: sugg.status,
        createdAt: sugg.createdAt
      });
      return acc;
    }, {});

    res.json({
      total: suggestions.length,
      byCityCount: Object.keys(byCity).length,
      byCity: Object.values(byCity)
    });

  } catch (error) {
    console.error('Error al obtener sugerencias:', error);
    res.status(500).json({ 
      error: 'Error al obtener sugerencias',
      message: error.message 
    });
  }
});

module.exports = router;
