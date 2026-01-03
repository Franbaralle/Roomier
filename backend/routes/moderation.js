const express = require('express');
const router = express.Router();
const User = require('../models/user');
const Report = require('../models/report');
const { verifyToken } = require('../middleware/auth');
const { apiLimiter } = require('../middleware/rateLimiter');

// Todas las rutas requieren autenticación
router.use(verifyToken);
router.use(apiLimiter);

// Reportar un usuario
router.post('/report', async (req, res) => {
    try {
        const { reportedUser, reason, description } = req.body;
        const reportedBy = req.username; // Del token JWT

        // Validaciones
        if (!reportedUser || !reason) {
            return res.status(400).json({ 
                error: 'Datos incompletos',
                message: 'Se requiere el usuario a reportar y la razón' 
            });
        }

        // No permitir auto-reporte
        if (reportedUser === reportedBy) {
            return res.status(400).json({ 
                error: 'Acción no permitida',
                message: 'No puedes reportarte a ti mismo' 
            });
        }

        // Verificar que el usuario reportado existe
        const userExists = await User.findOne({ username: reportedUser });
        if (!userExists) {
            return res.status(404).json({ 
                error: 'Usuario no encontrado',
                message: 'El usuario que intentas reportar no existe' 
            });
        }

        // Verificar si ya lo reportó antes
        const existingReport = await Report.findOne({ 
            reportedUser, 
            reportedBy 
        });

        if (existingReport) {
            return res.status(400).json({ 
                error: 'Reporte duplicado',
                message: 'Ya has reportado a este usuario anteriormente' 
            });
        }

        // Crear el reporte
        const newReport = new Report({
            reportedUser,
            reportedBy,
            reason,
            description: description || '',
            status: 'pending'
        });

        await newReport.save();

        // Agregar a la lista de reportedBy del usuario
        await User.findOneAndUpdate(
            { username: reportedUser },
            { $addToSet: { reportedBy: reportedBy } }
        );

        // Verificar si el usuario tiene muchos reportes (auto-moderación básica)
        const reportCount = await Report.countDocuments({ 
            reportedUser, 
            status: 'pending' 
        });

        let warningMessage = '';
        if (reportCount >= 5) {
            warningMessage = ' Este usuario está siendo revisado por múltiples reportes.';
        }

        res.status(201).json({ 
            message: 'Reporte enviado exitosamente. Nuestro equipo lo revisará pronto.' + warningMessage,
            reportId: newReport._id
        });

    } catch (error) {
        console.error('[ERROR] Error al reportar usuario:', error);
        res.status(500).json({ 
            error: 'Error del servidor',
            message: 'No se pudo procesar el reporte' 
        });
    }
});

// Bloquear un usuario
router.post('/block', async (req, res) => {
    try {
        const { blockedUser } = req.body;
        const currentUser = req.username; // Del token JWT

        // Validaciones
        if (!blockedUser) {
            return res.status(400).json({ 
                error: 'Datos incompletos',
                message: 'Se requiere el usuario a bloquear' 
            });
        }

        // No permitir auto-bloqueo
        if (blockedUser === currentUser) {
            return res.status(400).json({ 
                error: 'Acción no permitida',
                message: 'No puedes bloquearte a ti mismo' 
            });
        }

        // Verificar que el usuario a bloquear existe
        const userExists = await User.findOne({ username: blockedUser });
        if (!userExists) {
            return res.status(404).json({ 
                error: 'Usuario no encontrado',
                message: 'El usuario que intentas bloquear no existe' 
            });
        }

        // Agregar a la lista de bloqueados
        const user = await User.findOneAndUpdate(
            { username: currentUser },
            { $addToSet: { blockedUsers: blockedUser } },
            { new: true }
        );

        // Eliminar de matches mutuos si existían
        await User.findOneAndUpdate(
            { username: currentUser },
            { 
                $pull: { isMatch: blockedUser }
            }
        );

        await User.findOneAndUpdate(
            { username: blockedUser },
            { 
                $pull: { isMatch: currentUser }
            }
        );

        res.status(200).json({ 
            message: 'Usuario bloqueado exitosamente',
            blockedUsers: user.blockedUsers
        });

    } catch (error) {
        console.error('[ERROR] Error al bloquear usuario:', error);
        res.status(500).json({ 
            error: 'Error del servidor',
            message: 'No se pudo bloquear al usuario' 
        });
    }
});

// Desbloquear un usuario
router.post('/unblock', async (req, res) => {
    try {
        const { unblockedUser } = req.body;
        const currentUser = req.username; // Del token JWT

        // Validaciones
        if (!unblockedUser) {
            return res.status(400).json({ 
                error: 'Datos incompletos',
                message: 'Se requiere el usuario a desbloquear' 
            });
        }

        // Eliminar de la lista de bloqueados
        const user = await User.findOneAndUpdate(
            { username: currentUser },
            { $pull: { blockedUsers: unblockedUser } },
            { new: true }
        );

        res.status(200).json({ 
            message: 'Usuario desbloqueado exitosamente',
            blockedUsers: user.blockedUsers
        });

    } catch (error) {
        console.error('[ERROR] Error al desbloquear usuario:', error);
        res.status(500).json({ 
            error: 'Error del servidor',
            message: 'No se pudo desbloquear al usuario' 
        });
    }
});

// Obtener lista de usuarios bloqueados
router.get('/blocked', async (req, res) => {
    try {
        const currentUser = req.username; // Del token JWT

        const user = await User.findOne({ username: currentUser });
        
        if (!user) {
            return res.status(404).json({ 
                error: 'Usuario no encontrado' 
            });
        }

        res.status(200).json({ 
            blockedUsers: user.blockedUsers || []
        });

    } catch (error) {
        console.error('[ERROR] Error al obtener usuarios bloqueados:', error);
        res.status(500).json({ 
            error: 'Error del servidor',
            message: 'No se pudo obtener la lista de bloqueados' 
        });
    }
});

// Obtener mis reportes (que he hecho)
router.get('/my-reports', async (req, res) => {
    try {
        const currentUser = req.username; // Del token JWT

        const reports = await Report.find({ reportedBy: currentUser })
            .sort({ createdAt: -1 })
            .select('-__v');

        res.status(200).json({ 
            reports,
            total: reports.length
        });

    } catch (error) {
        console.error('[ERROR] Error al obtener reportes:', error);
        res.status(500).json({ 
            error: 'Error del servidor',
            message: 'No se pudieron obtener los reportes' 
        });
    }
});

// === RUTAS DE ADMINISTRACIÓN === //
// (Estas deberían tener un middleware de admin, por ahora están comentadas)

/*
// Obtener todos los reportes (ADMIN)
router.get('/admin/reports', async (req, res) => {
    try {
        const { status, limit = 50 } = req.query;
        
        const query = status ? { status } : {};
        
        const reports = await Report.find(query)
            .sort({ createdAt: -1 })
            .limit(parseInt(limit));

        res.status(200).json({ 
            reports,
            total: reports.length
        });

    } catch (error) {
        console.error('[ERROR] Error al obtener reportes:', error);
        res.status(500).json({ 
            error: 'Error del servidor' 
        });
    }
});

// Revisar un reporte (ADMIN)
router.put('/admin/reports/:reportId', async (req, res) => {
    try {
        const { reportId } = req.params;
        const { status, actionTaken, notes } = req.body;
        const adminUsername = req.username;

        const report = await Report.findByIdAndUpdate(
            reportId,
            {
                status,
                actionTaken,
                notes,
                reviewedBy: adminUsername,
                reviewDate: new Date()
            },
            { new: true }
        );

        if (!report) {
            return res.status(404).json({ error: 'Reporte no encontrado' });
        }

        res.status(200).json({ 
            message: 'Reporte actualizado',
            report
        });

    } catch (error) {
        console.error('[ERROR] Error al actualizar reporte:', error);
        res.status(500).json({ error: 'Error del servidor' });
    }
});
*/

module.exports = router;
