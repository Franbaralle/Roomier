const mongoose = require('mongoose');
const User = require('../models/user');

// URL de conexión a MongoDB (usar variable de entorno o la de Railway)
const MONGODB_URI = process.env.MONGODB_URI || 'tu_conexion_mongodb';

async function migratePreferences() {
    try {
        console.log('Conectando a MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('✓ Conectado a MongoDB\n');

        // Encontrar todos los usuarios que tienen preferences como array
        const users = await User.find({ preferences: { $type: 'array' } });
        
        console.log(`Encontrados ${users.length} usuarios con formato antiguo de preferences\n`);

        let migratedCount = 0;
        let errorCount = 0;

        for (const user of users) {
            try {
                console.log(`Migrando usuario: ${user.username}`);
                console.log(`  Preferences antiguo:`, user.preferences);

                // Guardar las preferencias antiguas en legacyPreferences
                const oldPrefs = Array.isArray(user.preferences) ? [...user.preferences] : [];
                
                // Convertir array de strings a objeto estructurado vacío
                // Los usuarios tendrán que volver a seleccionar sus preferencias con el nuevo sistema
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
                        $set: { preferences: newPreferences, legacyPreferences: oldPrefs }
                    }
                );

                migratedCount++;
                console.log(`  ✓ Usuario ${user.username} migrado exitosamente\n`);
            } catch (error) {
                errorCount++;
                console.error(`  ✗ Error migrando usuario ${user.username}:`, error.message, '\n');
            }
        }

        console.log('\n=== RESUMEN DE MIGRACIÓN ===');
        console.log(`Total usuarios procesados: ${users.length}`);
        console.log(`Migrados exitosamente: ${migratedCount}`);
        console.log(`Errores: ${errorCount}`);
        console.log('============================\n');

    } catch (error) {
        console.error('Error en la migración:', error);
    } finally {
        await mongoose.connection.close();
        console.log('Conexión cerrada');
        process.exit(0);
    }
}

// Ejecutar migración
migratePreferences();
