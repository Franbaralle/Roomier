const express = require('express');
const router = express.Router();
const Report = require('../models/report');
const User = require('../models/user');
const { verifyToken } = require('../middleware/auth');
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

// Obtener todos los reportes (con paginación y filtros)
router.get('/reports', verifyToken, isAdmin, async (req, res) => {
    try {
        const { 
            status = 'all', 
            page = 1, 
            limit = 20,
            sortBy = 'createdAt',
            order = 'desc'
        } = req.query;

        const query = status !== 'all' ? { status } : {};
        const skip = (page - 1) * limit;
        const sortOrder = order === 'desc' ? -1 : 1;

        const [reports, totalCount] = await Promise.all([
            Report.find(query)
                .sort({ [sortBy]: sortOrder })
                .skip(skip)
                .limit(Number(limit))
                .lean(),
            Report.countDocuments(query)
        ]);

        logger.info(`Admin ${req.user.username} fetched ${reports.length} reports (page ${page})`);

        res.status(200).json({
            reports,
            pagination: {
                currentPage: Number(page),
                totalPages: Math.ceil(totalCount / limit),
                totalReports: totalCount,
                reportsPerPage: Number(limit)
            }
        });
    } catch (error) {
        logger.error(`Error fetching reports: ${error.message}`);
        res.status(500).json({ message: 'Error al obtener reportes' });
    }
});

// Obtener estadísticas de reportes
router.get('/reports/stats', verifyToken, isAdmin, async (req, res) => {
    try {
        const stats = await Report.aggregate([
            {
                $facet: {
                    byStatus: [
                        { $group: { _id: '$status', count: { $sum: 1 } } }
                    ],
                    byReason: [
                        { $group: { _id: '$reason', count: { $sum: 1 } } }
                    ],
                    topReported: [
                        { $group: { _id: '$reportedUser', count: { $sum: 1 } } },
                        { $sort: { count: -1 } },
                        { $limit: 10 }
                    ],
                    recent: [
                        { $match: { status: 'pending' } },
                        { $count: 'pendingCount' }
                    ]
                }
            }
        ]);

        logger.info(`Admin ${req.user.username} fetched report statistics`);

        res.status(200).json({
            statistics: stats[0],
            generatedAt: new Date()
        });
    } catch (error) {
        logger.error(`Error fetching report stats: ${error.message}`);
        res.status(500).json({ message: 'Error al obtener estadísticas' });
    }
});

// Obtener detalles de un reporte específico
router.get('/reports/:reportId', verifyToken, isAdmin, async (req, res) => {
    try {
        const { reportId } = req.params;
        
        const report = await Report.findById(reportId).lean();
        
        if (!report) {
            return res.status(404).json({ message: 'Reporte no encontrado' });
        }

        // Obtener información adicional de los usuarios involucrados
        const [reportedUser, reporterUser] = await Promise.all([
            User.findOne({ username: report.reportedUser }).select('username email createdAt blockedUsers').lean(),
            User.findOne({ username: report.reportedBy }).select('username email createdAt').lean()
        ]);

        logger.info(`Admin ${req.user.username} viewed report ${reportId}`);

        res.status(200).json({
            report,
            reportedUserInfo: reportedUser,
            reporterInfo: reporterUser
        });
    } catch (error) {
        logger.error(`Error fetching report details: ${error.message}`);
        res.status(500).json({ message: 'Error al obtener detalles del reporte' });
    }
});

// Actualizar estado de un reporte
router.put('/reports/:reportId', verifyToken, isAdmin, async (req, res) => {
    try {
        const { reportId } = req.params;
        const { status, actionTaken, notes } = req.body;

        if (!status) {
            return res.status(400).json({ message: 'El estado es requerido' });
        }

        const validStatuses = ['pending', 'reviewed', 'action_taken', 'dismissed'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Estado no válido' });
        }

        const updateData = {
            status,
            reviewedBy: req.user.username,
            reviewDate: new Date()
        };

        if (actionTaken) {
            updateData.actionTaken = actionTaken;
        }

        if (notes) {
            updateData.adminNotes = notes;
        }

        const report = await Report.findByIdAndUpdate(
            reportId,
            updateData,
            { new: true }
        );

        if (!report) {
            return res.status(404).json({ message: 'Reporte no encontrado' });
        }

        logger.info(`Admin ${req.user.username} updated report ${reportId} to status: ${status}`);

        res.status(200).json({
            message: 'Reporte actualizado correctamente',
            report
        });
    } catch (error) {
        logger.error(`Error updating report: ${error.message}`);
        res.status(500).json({ message: 'Error al actualizar reporte' });
    }
});

// Tomar acción sobre un usuario reportado (suspender, banear, etc.)
router.post('/users/:username/action', verifyToken, isAdmin, async (req, res) => {
    try {
        const { username } = req.params;
        const { action, reason, duration } = req.body;

        const validActions = ['warning', 'suspend', 'ban', 'delete'];
        if (!validActions.includes(action)) {
            return res.status(400).json({ message: 'Acción no válida' });
        }

        const user = await User.findOne({ username });
        
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Aplicar la acción
        switch (action) {
            case 'warning':
                // Solo registrar en logs (o agregar campo warnings al modelo)
                logger.warn(`Admin ${req.user.username} issued warning to user ${username}: ${reason}`);
                break;
            
            case 'suspend':
                user.accountStatus = 'suspended';
                user.suspendedUntil = duration ? new Date(Date.now() + duration * 24 * 60 * 60 * 1000) : null;
                user.suspensionReason = reason;
                await user.save();
                logger.warn(`Admin ${req.user.username} suspended user ${username} for ${duration} days`);
                break;
            
            case 'ban':
                user.accountStatus = 'banned';
                user.banReason = reason;
                await user.save();
                logger.warn(`Admin ${req.user.username} permanently banned user ${username}`);
                break;
            
            case 'delete':
                await User.deleteOne({ username });
                logger.warn(`Admin ${req.user.username} deleted user ${username}`);
                break;
        }

        res.status(200).json({
            message: `Acción "${action}" aplicada correctamente`,
            username,
            action
        });
    } catch (error) {
        logger.error(`Error taking action on user: ${error.message}`);
        res.status(500).json({ message: 'Error al aplicar acción' });
    }
});

// Obtener lista de usuarios con más reportes
router.get('/users/most-reported', verifyToken, isAdmin, async (req, res) => {
    try {
        const { limit = 20 } = req.query;

        const mostReported = await Report.aggregate([
            { $group: { _id: '$reportedUser', reportCount: { $sum: 1 } } },
            { $sort: { reportCount: -1 } },
            { $limit: Number(limit) },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: 'username',
                    as: 'userInfo'
                }
            },
            {
                $project: {
                    username: '$_id',
                    reportCount: 1,
                    email: { $arrayElemAt: ['$userInfo.email', 0] },
                    accountStatus: { $arrayElemAt: ['$userInfo.accountStatus', 0] },
                    createdAt: { $arrayElemAt: ['$userInfo.createdAt', 0] }
                }
            }
        ]);

        logger.info(`Admin ${req.user.username} fetched most reported users`);

        res.status(200).json({
            users: mostReported,
            generatedAt: new Date()
        });
    } catch (error) {
        logger.error(`Error fetching most reported users: ${error.message}`);
        res.status(500).json({ message: 'Error al obtener usuarios más reportados' });
    }
});

module.exports = router;
