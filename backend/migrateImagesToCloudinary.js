const mongoose = require('mongoose');
const User = require('./models/user');
const { uploadImage } = require('./utils/cloudinary');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/roomier';

async function migrateImagesToCloudinary() {
    try {
        console.log('🚀 Iniciando migración de imágenes a Cloudinary...');
        
        // Conectar a MongoDB
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Conectado a MongoDB');

        // Encontrar usuarios con profilePhoto tipo Buffer (campo legacy)
        const usersWithBufferPhotos = await User.find({
            profilePhoto: { $exists: true, $type: 'binData' }
        });

        console.log(`📊 Encontrados ${usersWithBufferPhotos.length} usuarios con fotos en Buffer`);

        if (usersWithBufferPhotos.length === 0) {
            console.log('✨ No hay imágenes para migrar. ¡Todo listo!');
            process.exit(0);
        }

        let migratedCount = 0;
        let errorCount = 0;

        // Migrar cada usuario
        for (const user of usersWithBufferPhotos) {
            try {
                console.log(`\n🔄 Migrando foto de usuario: ${user.username}`);
                
                // Verificar que el Buffer existe y tiene contenido
                if (!user.profilePhoto || !Buffer.isBuffer(user.profilePhoto)) {
                    console.log(`⚠️  Usuario ${user.username} no tiene Buffer válido, saltando...`);
                    continue;
                }

                // Subir a Cloudinary
                const cloudinaryResult = await uploadImage(
                    user.profilePhoto,
                    'profile_photos',
                    `user_${user.username}`
                );

                // Guardar la imagen vieja en el campo legacy
                user.profilePhotoBuffer = user.profilePhoto;
                
                // Actualizar con la URL de Cloudinary
                user.profilePhoto = cloudinaryResult.secure_url;
                user.profilePhotoPublicId = cloudinaryResult.public_id;

                await user.save();

                console.log(`✅ Migrado: ${user.username} -> ${cloudinaryResult.secure_url}`);
                migratedCount++;

            } catch (error) {
                console.error(`❌ Error al migrar usuario ${user.username}:`, error.message);
                errorCount++;
            }
        }

        console.log('\n' + '='.repeat(50));
        console.log('📈 RESUMEN DE MIGRACIÓN');
        console.log('='.repeat(50));
        console.log(`✅ Migrados exitosamente: ${migratedCount}`);
        console.log(`❌ Errores: ${errorCount}`);
        console.log(`📊 Total procesados: ${usersWithBufferPhotos.length}`);
        console.log('='.repeat(50));

        if (migratedCount === usersWithBufferPhotos.length) {
            console.log('\n🎉 ¡Migración completada exitosamente!');
        } else {
            console.log('\n⚠️  Migración completada con algunos errores. Revisa los logs.');
        }

        await mongoose.disconnect();
        process.exit(0);

    } catch (error) {
        console.error('💥 Error fatal en la migración:', error);
        await mongoose.disconnect();
        process.exit(1);
    }
}

// Ejecutar migración
migrateImagesToCloudinary();
