const mongoose = require('mongoose');

const analyticsEventSchema = new mongoose.Schema({
  eventType: { 
    type: String, 
    required: true,
    enum: ['login', 'profile_view', 'match_action', 'message_sent', 'reveal_info', 'search', 'signup'],
    index: true
  },
  username: { 
    type: String, 
    required: true,
    index: true
  },
  metadata: {
    // Para profile_view: { viewedUser: 'username' }
    // Para match_action: { targetUser: 'username', action: 'like/dislike' }
    // Para message_sent: { recipientUser: 'username', chatId: 'id' }
    // Para reveal_info: { matchedUser: 'username', infoType: 'zones/budget/contact' }
    // Para search: { filters: {...} }
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  timestamp: { 
    type: Date, 
    default: Date.now,
    index: true
  },
  sessionId: { 
    type: String,
    required: false
  },
  ipAddress: { 
    type: String,
    required: false
  },
  userAgent: { 
    type: String,
    required: false
  }
});

// Índices compuestos para consultas comunes
analyticsEventSchema.index({ eventType: 1, timestamp: -1 });
analyticsEventSchema.index({ username: 1, timestamp: -1 });
analyticsEventSchema.index({ username: 1, eventType: 1 });

const AnalyticsEvent = mongoose.model('AnalyticsEvent', analyticsEventSchema);

module.exports = AnalyticsEvent;
