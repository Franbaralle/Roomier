const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
    reportedUser: {
        type: String,
        required: true,
        index: true
    },
    reportedBy: {
        type: String,
        required: true,
        index: true
    },
    reason: {
        type: String,
        enum: [
            'inappropriate_behavior',      // Comportamiento inapropiado
            'fake_profile',                // Perfil falso
            'harassment',                  // Acoso
            'spam',                        // Spam
            'offensive_content',           // Contenido ofensivo
            'scam',                        // Estafa
            'underage',                    // Menor de edad
            'impersonation',               // Suplantación de identidad
            'violencia_genero',            // Violencia de género
            'other'                        // Otro
        ],
        required: true
    },
    description: {
        type: String,
        required: false,
        maxlength: 500
    },
    status: {
        type: String,
        enum: ['pending', 'reviewed', 'action_taken', 'dismissed'],
        default: 'pending'
    },
    reviewedBy: {
        type: String, // Admin username
        required: false
    },
    reviewDate: {
        type: Date,
        required: false
    },
    actionTaken: {
        type: String,
        enum: ['none', 'warning', 'temporary_ban', 'permanent_ban', 'profile_removal'],
        required: false
    },
    notes: {
        type: String, // Notas del moderador
        required: false
    },
    createdAt: {
        type: Date,
        default: Date.now,
        index: true
    }
});

// Índice compuesto para evitar reportes duplicados
reportSchema.index({ reportedUser: 1, reportedBy: 1 }, { unique: true });

const Report = mongoose.model('Report', reportSchema);

module.exports = Report;
