// Middleware de rate limiting para proteger contra ataques de fuerza bruta
const rateLimit = require('express-rate-limit');

// Rate limiter estricto para login (prevenir fuerza bruta)
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 5, // 5 intentos por ventana
    message: {
        error: 'Demasiados intentos de inicio de sesión',
        message: 'Has excedido el número de intentos. Por favor, intenta de nuevo en 15 minutos.',
        retryAfter: '15 minutos'
    },
    standardHeaders: true, // Retorna info de rate limit en headers `RateLimit-*`
    legacyHeaders: false, // Deshabilita headers `X-RateLimit-*`
    validate: { trustProxy: false }, // Desactivar validación de trust proxy
});

// Rate limiter para registro
const registerLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 3, // 3 registros por hora por IP
    message: {
        error: 'Demasiados registros',
        message: 'Has excedido el número de registros permitidos. Por favor, intenta más tarde.',
        retryAfter: '1 hora'
    },
    standardHeaders: true,
    legacyHeaders: false,
    validate: { trustProxy: false }, // Desactivar validación de trust proxy
});

// Rate limiter general para API
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 100, // 100 requests por ventana
    message: {
        error: 'Demasiadas solicitudes',
        message: 'Has excedido el número de solicitudes permitidas. Por favor, intenta más tarde.',
        retryAfter: '15 minutos'
    },
    standardHeaders: true,
    legacyHeaders: false,
    validate: { trustProxy: false }, // Desactivar validación de trust proxy
});

// Rate limiter para cambio de contraseña
const passwordResetLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 3, // 3 intentos por hora
    message: {
        error: 'Demasiados intentos',
        message: 'Has excedido el número de intentos de cambio de contraseña. Por favor, intenta más tarde.',
        retryAfter: '1 hora'
    },
    standardHeaders: true,
    legacyHeaders: false
});

// Rate limiter para mensajes de chat
const chatLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minuto
    max: 20, // 20 mensajes por minuto
    message: {
        error: 'Demasiados mensajes',
        message: 'Estás enviando mensajes muy rápido. Por favor, espera un momento.',
        retryAfter: '1 minuto'
    },
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        return req.username || req.user?.username || 'anonymous';
    }
});

// Rate limiter para subida de imágenes
const uploadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 10, // 10 uploads por hora
    message: {
        error: 'Demasiadas subidas',
        message: 'Has excedido el número de subidas permitidas. Por favor, intenta más tarde.',
        retryAfter: '1 hora'
    },
    standardHeaders: true,
    legacyHeaders: false
});

module.exports = {
    loginLimiter,
    registerLimiter,
    apiLimiter,
    passwordResetLimiter,
    chatLimiter,
    uploadLimiter
};
