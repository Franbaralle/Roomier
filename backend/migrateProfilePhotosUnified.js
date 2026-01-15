/**
 * Script de Migración: Unificar profilePhoto → profilePhotos[0]
 * 
 * Este script migra usuarios que tienen foto en el campo legacy profilePhoto
 * y la mueve al nuevo array profilePhotos como primer elemento.
 * 
 * Ejecutar: node migrateProfilePhotosUnified.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/user');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/flutter_auth';

async function migrateProfilePhotos() {
    try {
        console.log('🔌 Conectando a MongoDB...');
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Conectado exitosamente\n');

        // Buscar usuarios que tengan profilePhoto pero NO tengan profilePhotos o tengan array vacío
        const usersToMigrate = await User.find({
            $or: [
                { profilePhoto: { $exists: true, $ne: null, $ne: '' }, profilePhotos: { $exists: false } },
                { profilePhoto: { $exists: true, $ne: null, $ne: '' }, profilePhotos: { $size: 0 } }
            ]
        });

        console.log(`📊 Usuarios encontrados para migrar: ${usersToMigrate.length}\n`);

        if (usersToMigrate.length === 0) {
            console.log('✅ No hay usuarios que necesiten migración');
            await mongoose.disconnect();
            return;
        }

        let migrated = 0;
        let errors = 0;

        for (const user of usersToMigrate) {
            try {
                console.log(`\n🔄 Migrando usuario: ${user.username}`);
                console.log(`   - profilePhoto: ${user.profilePhoto ? 'Sí' : 'No'}`);
                console.log(`   - profilePhotoPublicId: ${user.profilePhotoPublicId ? 'Sí' : 'No'}`);
                console.log(`   - profilePhotos actual: ${user.profilePhotos ? user.profilePhotos.length : 0} fotos`);

                // Crear array de profilePhotos si no existe
                if (!user.profilePhotos) {
                    user.profilePhotos = [];
                }

                // Agregar la foto legacy como primera foto
                if (user.profilePhoto && user.profilePhotoPublicId) {
                    user.profilePhotos.unshift({
                        url: user.profilePhoto,
                        publicId: user.profilePhotoPublicId
                    });

                    console.log(`   ✅ Foto agregada a profilePhotos[0]`);
                    console.log(`      URL: ${user.profilePhoto.substring(0, 50)}...`);
                } else if (user.profilePhoto && !user.profilePhotoPublicId) {
                    // Si solo tiene URL pero no publicId (caso raro)
                    user.profilePhotos.unshift({
                        url: user.profilePhoto,
                        publicId: `legacy_${user.username}_${Date.now()}`
                    });

                    console.log(`   ⚠️  Foto sin publicId, asignando uno generado`);
                }

                // Guardar cambios
                await user.save();
                migrated++;

                console.log(`   ✅ Usuario migrado exitosamente`);
                console.log(`   📸 Total fotos ahora: ${user.profilePhotos.length}`);

            } catch (error) {
                errors++;
                console.error(`   ❌ Error migrando ${user.username}:`, error.message);
            }
        }

        console.log('\n' + '='.repeat(60));
        console.log('📊 RESUMEN DE MIGRACIÓN');
        console.log('='.repeat(60));
        console.log(`✅ Usuarios migrados: ${migrated}`);
        console.log(`❌ Errores: ${errors}`);
        console.log(`📊 Total procesados: ${usersToMigrate.length}`);
        console.log('='.repeat(60) + '\n');

        // Verificar resultado
        console.log('🔍 Verificando migración...');
        const usersWithPhotos = await User.find({ 'profilePhotos.0': { $exists: true } });
        console.log(`✅ Usuarios con al menos 1 foto en profilePhotos: ${usersWithPhotos.length}\n`);

        console.log('✅ Migración completada');
        await mongoose.disconnect();
        console.log('🔌 Desconectado de MongoDB');

    } catch (error) {
        console.error('❌ Error en migración:', error);
        await mongoose.disconnect();
        process.exit(1);
    }
}

// Ejecutar migración
console.log('🚀 Iniciando migración de fotos de perfil...\n');
migrateProfilePhotos();
