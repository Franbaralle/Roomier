const mongoose = require('mongoose');

const tokenBlacklistSchema = new mongoose.Schema({
    token: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    username: {
        type: String,
        required: true
    },
    reason: {
        type: String,
        enum: ['logout', 'security', 'admin_revoke'],
        default: 'logout'
    },
    expiresAt: {
        type: Date,
        required: true,
        index: true
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 86400 // El documento se eliminará automáticamente después de 24h (TTL index)
    }
});

// Índice compuesto para búsquedas rápidas
tokenBlacklistSchema.index({ token: 1, expiresAt: 1 });

const TokenBlacklist = mongoose.model('TokenBlacklist', tokenBlacklistSchema);

module.exports = TokenBlacklist;
