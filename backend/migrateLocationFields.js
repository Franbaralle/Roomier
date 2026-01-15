/**
 * Script de migración para actualizar los campos de ubicación
 * de usuarios existentes al nuevo sistema con API Georef
 * 
 * Ejecutar con: node migrateLocationFields.js
 */

const mongoose = require('mongoose');
const User = require('./models/user');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/roomier';

async function migrateLocationFields() {
    try {
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Conectado a MongoDB');

        const users = await User.find({});
        console.log(`📊 Total de usuarios encontrados: ${users.length}`);

        let migrated = 0;
        let skipped = 0;
        let errors = 0;

        for (const user of users) {
            try {
                const housingInfo = user.housingInfo || {};
                let needsUpdate = false;

                // Si ya tiene los campos nuevos, saltar
                if (housingInfo.originProvince || housingInfo.destinationProvince) {
                    console.log(`⏭️  Usuario ${user.username} ya tiene campos nuevos, saltando...`);
                    skipped++;
                    continue;
                }

                const updates = {};

                // Migrar city a destinationProvince (o originProvince si tiene lugar)
                if (housingInfo.city) {
                    if (housingInfo.hasPlace) {
                        updates['housingInfo.originProvince'] = housingInfo.city;
                        updates['housingInfo.destinationProvince'] = housingInfo.city;
                    } else {
                        updates['housingInfo.destinationProvince'] = housingInfo.city;
                        // Dejar originProvince vacío, el usuario lo completará
                    }
                    needsUpdate = true;
                }

                // Migrar preferredZones a los campos específicos
                if (housingInfo.preferredZones && housingInfo.preferredZones.length > 0) {
                    if (housingInfo.hasPlace) {
                        // Si tiene lugar, los barrios van a Origin
                        updates['housingInfo.specificNeighborhoodsOrigin'] = housingInfo.preferredZones;
                    } else {
                        // Si busca lugar, los barrios van a Destination
                        updates['housingInfo.specificNeighborhoodsDestination'] = housingInfo.preferredZones;
                    }
                    needsUpdate = true;
                }

                // Mantener los campos legacy para compatibilidad
                // (no los borramos)

                if (needsUpdate) {
                    await User.updateOne(
                        { _id: user._id },
                        { $set: updates }
                    );
                    
                    console.log(`✅ Migrado: ${user.username}`);
                    console.log(`   - hasPlace: ${housingInfo.hasPlace}`);
                    console.log(`   - city → ${updates['housingInfo.originProvince'] ? 'originProvince' : 'destinationProvince'}: ${housingInfo.city || 'N/A'}`);
                    console.log(`   - preferredZones → ${housingInfo.hasPlace ? 'specificNeighborhoodsOrigin' : 'specificNeighborhoodsDestination'}: ${housingInfo.preferredZones?.length || 0} barrios`);
                    
                    migrated++;
                } else {
                    console.log(`⚠️  Usuario ${user.username} sin datos de ubicación para migrar`);
                    skipped++;
                }

            } catch (error) {
                console.error(`❌ Error migrando usuario ${user.username}:`, error.message);
                errors++;
            }
        }

        console.log('\n========================================');
        console.log('📈 RESUMEN DE MIGRACIÓN');
        console.log('========================================');
        console.log(`✅ Usuarios migrados: ${migrated}`);
        console.log(`⏭️  Usuarios saltados: ${skipped}`);
        console.log(`❌ Errores: ${errors}`);
        console.log(`📊 Total procesados: ${users.length}`);
        console.log('========================================\n');

        if (migrated > 0) {
            console.log('✨ Migración completada con éxito!');
            console.log('⚠️  NOTA: Los campos legacy (city, generalZone, preferredZones) se mantienen para compatibilidad.');
            console.log('⚠️  Los usuarios deberán completar campos faltantes al editar su perfil.');
        }

    } catch (error) {
        console.error('❌ Error en la migración:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Desconectado de MongoDB');
    }
}

// Ejecutar migración
console.log('🚀 Iniciando migración de campos de ubicación...\n');
migrateLocationFields();
