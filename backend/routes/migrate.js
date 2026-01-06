const express = require('express');
const router = express.Router();
const User = require('../models/user');

/**
 * GET /api/migrate/preferences
 * Endpoint temporal para migrar preferencias de formato array a objeto
 * IMPORTANTE: Eliminar este endpoint después de usarlo en producción
 */
router.get('/preferences', async (req, res) => {
    try {
        // Seguridad básica: requiere clave secreta
        const { secret } = req.query;
        if (secret !== 'migrate2024') {
            return res.status(403).json({ 
                success: false, 
                message: 'No autorizado' 
            });
        }

        console.log('\n=== INICIANDO MIGRACIÓN DE PREFERENCIAS ===\n');

        // Encontrar todos los usuarios que tienen preferences como array
        const users = await User.find({ preferences: { $type: 'array' } });
        
        console.log(`Encontrados ${users.length} usuarios con formato antiguo de preferences\n`);

        const results = {
            total: users.length,
            migrated: 0,
            errors: 0,
            details: []
        };

        for (const user of users) {
            try {
                console.log(`Migrando usuario: ${user.username}`);
                
                // Guardar las preferencias antiguas en legacyPreferences
                const oldPrefs = [...user.preferences];
                
                // Convertir array de strings a objeto estructurado vacío
                const newPreferences = {
                    convivencia: {
                        hogar: [],
                        social: [],
                        mascotas: []
                    },
                    gastronomia: {
                        habitos: [],
                        bebidas: [],
                        habilidades: []
                    },
                    deporte: {
                        intensidad: [],
                        menteCuerpo: [],
                        deportesPelota: [],
                        aguaNaturaleza: []
                    },
                    entretenimiento: {
                        pantalla: [],
                        musica: [],
                        gaming: []
                    },
                    creatividad: {
                        artesPlasticas: [],
                        tecnologia: [],
                        moda: []
                    },
                    interesesSociales: {
                        causas: [],
                        conocimiento: []
                    }
                };

                // Actualizar usando updateOne para evitar validaciones del modelo
                await User.updateOne(
                    { _id: user._id },
                    { 
                        $set: { 
                            preferences: newPreferences, 
                            legacyPreferences: oldPrefs 
                        }
                    }
                );

                results.migrated++;
                results.details.push({
                    username: user.username,
                    status: 'success',
                    oldPreferences: oldPrefs
                });
                
                console.log(`  ✓ Usuario ${user.username} migrado exitosamente\n`);
            } catch (error) {
                results.errors++;
                results.details.push({
                    username: user.username,
                    status: 'error',
                    error: error.message
                });
                console.error(`  ✗ Error migrando usuario ${user.username}:`, error.message, '\n');
            }
        }

        console.log('\n=== RESUMEN DE MIGRACIÓN ===');
        console.log(`Total usuarios procesados: ${results.total}`);
        console.log(`Migrados exitosamente: ${results.migrated}`);
        console.log(`Errores: ${results.errors}`);
        console.log('============================\n');

        return res.json({
            success: true,
            message: 'Migración completada',
            results
        });

    } catch (error) {
        console.error('Error en la migración:', error);
        return res.status(500).json({
            success: false,
            message: 'Error en la migración',
            error: error.message
        });
    }
});

/**
 * GET /api/migrate/status
 * Verificar cuántos usuarios necesitan migración
 */
router.get('/status', async (req, res) => {
    try {
        const usersWithOldFormat = await User.countDocuments({ preferences: { $type: 'array' } });
        const usersWithNewFormat = await User.countDocuments({ preferences: { $type: 'object' } });
        const totalUsers = await User.countDocuments({});

        return res.json({
            success: true,
            totalUsers,
            usersWithOldFormat,
            usersWithNewFormat,
            needsMigration: usersWithOldFormat > 0
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

module.exports = router;
