// Middleware para verificar JWT tokens
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/security');

// Middleware para verificar token en rutas protegidas
const verifyToken = (req, res, next) => {
    try {
        // Obtener token del header Authorization
        const authHeader = req.headers['authorization'];
        
        if (!authHeader) {
            return res.status(401).json({ 
                error: 'Acceso denegado',
                message: 'No se proporcionó token de autenticación' 
            });
        }

        // El formato esperado es: "Bearer TOKEN"
        const token = authHeader.startsWith('Bearer ') 
            ? authHeader.slice(7) 
            : authHeader;

        if (!token) {
            return res.status(401).json({ 
                error: 'Acceso denegado',
                message: 'Token inválido' 
            });
        }

        // Verificar y decodificar el token
        const decoded = jwt.verify(token, jwtSecret);
        
        // Agregar información del usuario al request
        req.user = decoded;
        req.username = decoded.username;
        
        // Continuar con la siguiente función
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ 
                error: 'Token expirado',
                message: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.' 
            });
        } else if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ 
                error: 'Token inválido',
                message: 'El token proporcionado no es válido.' 
            });
        } else {
            return res.status(500).json({ 
                error: 'Error en la verificación',
                message: 'Error al verificar el token de autenticación.' 
            });
        }
    }
};

// Middleware opcional - no bloquea si no hay token
const optionalToken = (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        
        if (authHeader) {
            const token = authHeader.startsWith('Bearer ') 
                ? authHeader.slice(7) 
                : authHeader;
                
            if (token) {
                const decoded = jwt.verify(token, jwtSecret);
                req.user = decoded;
                req.username = decoded.username;
            }
        }
        
        next();
    } catch (error) {
        // Si hay error, simplemente continuamos sin usuario autenticado
        next();
    }
};

module.exports = {
    verifyToken,
    optionalToken
};
