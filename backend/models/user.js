const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  email: { type: String, required: false },
  birthdate: { type: Date, required: false },
  gender: { type: String, enum: ['male', 'female', 'other'], required: false }, // Género del usuario
  
  // Intereses/hobbies (PÚBLICO) - Sistema categorizado
  preferences: {
    convivencia: {
      hogar: [{ type: String }], // Plantas/Jardinería, Decoración, DIY, etc.
      social: [{ type: String }], // Anfitrión de cenas, Salidas nocturnas, etc.
      mascotas: [{ type: String }] // Dog lover, Cat lover, etc.
    },
    gastronomia: {
      habitos: [{ type: String }], // Vegetariana, Vegana, etc.
      bebidas: [{ type: String }], // Café de especialidad, etc.
      habilidades: [{ type: String }] // Repostería, Parrillero, etc.
    },
    deporte: {
      intensidad: [{ type: String }], // Gimnasio, Crossfit, etc.
      menteCuerpo: [{ type: String }], // Yoga, Meditación, etc.
      deportesPelota: [{ type: String }], // Fútbol, Básquet, etc.
      aguaNaturaleza: [{ type: String }] // Trekking, Surf, etc.
    },
    entretenimiento: {
      pantalla: [{ type: String }], // Cine independiente, etc.
      musica: [{ type: String }], // Conciertos, Festivales, etc.
      gaming: [{ type: String }] // Videojuegos competitivos, etc.
    },
    creatividad: {
      artesPlasticas: [{ type: String }], // Dibujo/Pintura, etc.
      tecnologia: [{ type: String }], // Programación, IA, etc.
      moda: [{ type: String }] // Upcycling, Vintage, etc.
    },
    interesesSociales: {
      causas: [{ type: String }], // Activismo ambiental, etc.
      conocimiento: [{ type: String }] // Idiomas, Historia, etc.
    }
  },
  
  // Legacy preferences field para migración gradual
  legacyPreferences: [{ type: String }],
  
  // Preferencias de roommate (PÚBLICO - para filtrado de matching)
  roommatePreferences: {
    gender: { type: String, enum: ['male', 'female', 'both'], default: 'both' }, // Género preferido
    ageMin: { type: Number, min: 18, max: 100, required: false }, // Edad mínima
    ageMax: { type: Number, min: 18, max: 100, required: false } // Edad máxima
  },
  
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
  
  // Fotos de perfil (URLs de Cloudinary) - hasta 10 fotos
  profilePhotos: [{
    url: { type: String, required: true }, // URL de Cloudinary
    publicId: { type: String, required: true }, // Public ID en Cloudinary para eliminación
    isPrimary: { type: Boolean, default: false } // Primera foto es la principal
  }],
  
  // Fotos del hogar (solo si hasPlace es true) - ilimitadas
  homePhotos: [{
    url: { type: String, required: true }, // URL de Cloudinary
    publicId: { type: String, required: true }, // Public ID en Cloudinary para eliminación
    description: { type: String, required: false } // Descripción opcional de la foto
  }],
  
  // Campos legacy - mantener para migración gradual
  profilePhoto: { type: String, required: false }, // URL de Cloudinary (deprecated)
  profilePhotoPublicId: { type: String, required: false }, // Public ID en Cloudinary (deprecated)
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