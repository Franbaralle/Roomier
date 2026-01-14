const User = require('../models/user');
const logger = require('../utils/logger');

// Middleware para verificar que el usuario es admin
const isAdmin = async (req, res, next) => {
    try {
        const username = req.user.username; // Viene del verifyToken middleware
        const user = await User.findOne({ username });
        
        if (!user || !user.isAdmin) {
            logger.warn(`Unauthorized admin access attempt by ${username}`);
            return res.status(403).json({ message: 'Acceso denegado. Solo administradores.' });
        }
        
        next();
    } catch (error) {
        logger.error(`Error in isAdmin middleware: ${error.message}`);
        res.status(500).json({ message: 'Error de servidor' });
    }
};

module.exports = { isAdmin };
