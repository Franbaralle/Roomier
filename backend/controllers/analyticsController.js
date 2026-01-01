const AnalyticsEvent = require('../models/analyticsEvent');
const logger = require('../utils/logger');

// Trackear un evento de analytics
exports.trackEvent = async (req, res) => {
  try {
    const { eventType, metadata } = req.body;
    const username = req.user.username; // Del token JWT

    if (!eventType) {
      return res.status(400).json({ message: 'eventType es requerido' });
    }

    const event = new AnalyticsEvent({
      eventType,
      username,
      metadata: metadata || {},
      sessionId: req.sessionID || null,
      ipAddress: req.ip || req.connection.remoteAddress,
      userAgent: req.get('user-agent')
    });

    await event.save();
    logger.info(`Analytics event tracked: ${eventType} by ${username}`);
    
    res.status(201).json({ message: 'Evento registrado', eventId: event._id });
  } catch (error) {
    logger.error(`Error tracking analytics event: ${error.message}`);
    res.status(500).json({ message: 'Error al registrar evento', error: error.message });
  }
};

// Obtener estadísticas generales (solo admin)
exports.getGlobalStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const dateFilter = {};
    if (startDate) dateFilter.$gte = new Date(startDate);
    if (endDate) dateFilter.$lte = new Date(endDate);
    
    const matchStage = Object.keys(dateFilter).length > 0 
      ? { timestamp: dateFilter }
      : {};

    // Contar eventos por tipo
    const eventCounts = await AnalyticsEvent.aggregate([
      { $match: matchStage },
      { $group: { _id: '$eventType', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);

    // Usuarios activos únicos
    const activeUsers = await AnalyticsEvent.distinct('username', matchStage);

    // Eventos por día (últimos 30 días)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const eventsPerDay = await AnalyticsEvent.aggregate([
      { $match: { timestamp: { $gte: thirtyDaysAgo } } },
      { 
        $group: { 
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } },
          count: { $sum: 1 }
        } 
      },
      { $sort: { _id: 1 } }
    ]);

    // Top usuarios más activos
    const topUsers = await AnalyticsEvent.aggregate([
      { $match: matchStage },
      { $group: { _id: '$username', eventCount: { $sum: 1 } } },
      { $sort: { eventCount: -1 } },
      { $limit: 10 }
    ]);

    res.status(200).json({
      eventCounts,
      activeUsersCount: activeUsers.length,
      eventsPerDay,
      topUsers
    });
  } catch (error) {
    logger.error(`Error getting global stats: ${error.message}`);
    res.status(500).json({ message: 'Error al obtener estadísticas', error: error.message });
  }
};

// Obtener estadísticas de un usuario específico
exports.getUserStats = async (req, res) => {
  try {
    const username = req.user.username;
    const { startDate, endDate } = req.query;
    
    const dateFilter = { username };
    if (startDate) dateFilter.timestamp = { $gte: new Date(startDate) };
    if (endDate) {
      dateFilter.timestamp = dateFilter.timestamp || {};
      dateFilter.timestamp.$lte = new Date(endDate);
    }

    // Eventos por tipo para este usuario
    const userEventCounts = await AnalyticsEvent.aggregate([
      { $match: dateFilter },
      { $group: { _id: '$eventType', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);

    // Total de eventos
    const totalEvents = await AnalyticsEvent.countDocuments(dateFilter);

    // Último login
    const lastLogin = await AnalyticsEvent.findOne({ 
      username, 
      eventType: 'login' 
    }).sort({ timestamp: -1 });

    // Actividad en los últimos 7 días
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentActivity = await AnalyticsEvent.aggregate([
      { $match: { username, timestamp: { $gte: sevenDaysAgo } } },
      { 
        $group: { 
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$timestamp' } },
          count: { $sum: 1 }
        } 
      },
      { $sort: { _id: 1 } }
    ]);

    res.status(200).json({
      username,
      totalEvents,
      eventCounts: userEventCounts,
      lastLogin: lastLogin ? lastLogin.timestamp : null,
      recentActivity
    });
  } catch (error) {
    logger.error(`Error getting user stats: ${error.message}`);
    res.status(500).json({ message: 'Error al obtener estadísticas', error: error.message });
  }
};

// Obtener eventos recientes (para debugging)
exports.getRecentEvents = async (req, res) => {
  try {
    const { limit = 50, eventType, username } = req.query;
    
    const filter = {};
    if (eventType) filter.eventType = eventType;
    if (username) filter.username = username;

    const events = await AnalyticsEvent.find(filter)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .select('-__v');

    res.status(200).json({ events, count: events.length });
  } catch (error) {
    logger.error(`Error getting recent events: ${error.message}`);
    res.status(500).json({ message: 'Error al obtener eventos', error: error.message });
  }
};
