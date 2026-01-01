// Configuración de seguridad para la aplicación
module.exports = {
    // Clave secreta para JWT - EN PRODUCCIÓN DEBE ESTAR EN VARIABLE DE ENTORNO
    jwtSecret: process.env.JWT_SECRET || '614ck63rry5_roomier_secret_key_2025',
    
    // Tiempo de expiración del token
    jwtExpiration: '24h',
    
    // Configuración de bcrypt
    bcryptSaltRounds: 10,
    
    // MongoDB URI
    mongodbUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/roomier'
};
