const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  email: { type: String, required: false },
  birthdate: { type: Date, required: false },
  
  // Intereses/hobbies (PÚBLICO)
  preferences: [{type: String}],
  
  // Información personal básica (PÚBLICO excepto religión y política)
  personalInfo: {
    job: {type: String, required: false},
    religion: {type: String, required: false}, // PRIVADO
    politicPreference: {type: String, required: false}, // PRIVADO
    aboutMe: {type: String, required: false}
  },
  
  // Hábitos de convivencia (PÚBLICO)
  livingHabits: {
    smoker: { type: Boolean, default: false }, // Fuma
    hasPets: { type: Boolean, default: false }, // Tiene mascotas
    acceptsPets: { type: Boolean, default: false }, // Acepta mascotas
    cleanliness: { type: String, enum: ['low', 'normal', 'high'], default: 'normal' }, // Nivel de limpieza
    noiseLevel: { type: String, enum: ['quiet', 'normal', 'social'], default: 'normal' }, // Nivel de ruido
    schedule: { type: String, enum: ['early', 'normal', 'night'], default: 'normal' }, // Horarios
    socialLevel: { type: String, enum: ['independent', 'friendly', 'very_social'], default: 'friendly' }, // Nivel social
    hasGuests: { type: Boolean, default: false }, // Recibe visitas frecuentes
    drinker: { type: String, enum: ['never', 'social', 'regular'], default: 'social' } // Consumo de alcohol
  },
  
  // Información de vivienda (PRIVADO - solo para algoritmo)
  housingInfo: {
    budgetMin: { type: Number, required: false }, // PRIVADO
    budgetMax: { type: Number, required: false }, // PRIVADO
    preferredZones: [{ type: String }], // PRIVADO hasta match
    hasPlace: { type: Boolean, default: false }, // PÚBLICO - ¿Tiene lugar o busca?
    moveInDate: { type: String, required: false }, // PÚBLICO - Solo mes/trimestre (ej: "Enero 2026", "Q1 2026")
    stayDuration: { type: String, enum: ['3months', '6months', '1year', 'longterm'], required: false }, // PÚBLICO
    city: { type: String, required: false }, // PÚBLICO - Ciudad
    generalZone: { type: String, required: false } // PÚBLICO - Zona amplia (ej: "Zona Norte", "Centro")
  },
  
  // Deal Breakers (PÚBLICO - para filtrado automático)
  dealBreakers: {
    noSmokers: { type: Boolean, default: false }, // No acepta fumadores
    noPets: { type: Boolean, default: false }, // No acepta mascotas
    noParties: { type: Boolean, default: false }, // No acepta fiestas
    noChildren: { type: Boolean, default: false } // No acepta niños
  },
  
  // Verificación y seguridad (PRIVADO)
  verification: {
    emailVerified: { type: Boolean, default: false },
    phoneNumber: { type: String, required: false },
    phoneVerified: { type: Boolean, default: false },
    idVerified: { type: Boolean, default: false }, // DNI verificado
    selfieVerified: { type: Boolean, default: false }, // Selfie verification
    verificationCode: { type: String, required: false }
  },
  
  // Revelación progresiva (qué información ha desbloqueado con cada match)
  revealedInfo: [{
    matchedUser: { type: String }, // username del match
    revealedZones: { type: Boolean, default: false },
    revealedBudget: { type: Boolean, default: false },
    revealedContact: { type: Boolean, default: false }
  }],
  
  // Foto de perfil (URL de Cloudinary)
  profilePhoto: { type: String, required: false }, // URL de Cloudinary
  profilePhotoPublicId: { type: String, required: false }, // Public ID en Cloudinary para eliminación
  
  // Campos obsoletos - mantener para migración gradual
  profilePhotoBuffer: { type: Buffer, required: false }, // Buffer legacy (deprecated)
  
  // Token FCM para notificaciones push
  fcmToken: { type: String, required: false }, // Token de Firebase Cloud Messaging
  
  verificationCode: { type: String, required: false }, // Mantener por retrocompatibilidad
  isVerified: { type: Boolean, default: false }, // Mantener por retrocompatibilidad
  isMatch: [{ type:String }],
  notMatch: [{ type: String }],
  reportedBy: [{ type: String }], // Lista de usuarios que lo reportaron
  blockedUsers: [{ type: String }], // Usuarios que bloqueó
  isAdmin: { type: Boolean, default: false }, // Flag de administrador
  accountStatus: { type: String, enum: ['active', 'suspended', 'banned'], default: 'active' },
  suspendedUntil: { type: Date, required: false },
  suspensionReason: { type: String, required: false },
  banReason: { type: String, required: false },
  chatId: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat', required: false },
  createdAt: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

module.exports = User;