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

        // Acceder directamente a la colección sin pasar por el modelo
        // para evitar conversiones automáticas de Mongoose
        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');

        // Encontrar usuarios con profilePhoto que no hayan sido migrados
        const usersWithBufferPhotos = await usersCollection.find({
            profilePhoto: { $exists: true, $ne: null },
            profilePhotoPublicId: { $exists: false }
        }).toArray();

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
                
                // Verificar que el profilePhoto existe
                if (!user.profilePhoto) {
                    console.log(`⚠️  Usuario ${user.username} no tiene foto, saltando...`);
                    continue;
                }

                // Si ya es una URL de Cloudinary (string que empieza con http), saltar
                if (typeof user.profilePhoto === 'string' && user.profilePhoto.startsWith('http')) {
                    console.log(`⚠️  Usuario ${user.username} ya tiene URL de Cloudinary, saltando...`);
                    continue;
                }

                // Convertir a Buffer
                let photoBuffer;
                
                // MongoDB almacena Binary data como objeto Binary con propiedad buffer
                if (user.profilePhoto && user.profilePhoto.buffer && Buffer.isBuffer(user.profilePhoto.buffer)) {
                    photoBuffer = user.profilePhoto.buffer;
                    console.log(`   📦 Encontrado Binary object con buffer de ${photoBuffer.length} bytes`);
                } else if (Buffer.isBuffer(user.profilePhoto)) {
                    photoBuffer = user.profilePhoto;
                    console.log(`   📦 Buffer directo de ${photoBuffer.length} bytes`);
                } else if (typeof user.profilePhoto === 'string') {
                    // Es un string, intentar diferentes encodings
                    if (user.profilePhoto.startsWith('http')) {
                        console.log(`   ⚠️  Ya es una URL, saltando...`);
                        continue;
                    }
                    // Primero intentar como base64
                    try {
                        photoBuffer = Buffer.from(user.profilePhoto, 'base64');
                    } catch (e) {
                        // Si falla, intentar como latin1 (binary)
                        photoBuffer = Buffer.from(user.profilePhoto, 'latin1');
                    }
                    console.log(`   📦 String convertido a Buffer de ${photoBuffer.length} bytes`);
                } else {
                    console.log(`   ❌ Tipo no reconocido: ${typeof user.profilePhoto}`);
                    continue;
                }

                // Validar que el buffer tiene contenido razonable (> 1KB para una imagen)
                if (photoBuffer.length < 1024) {
                    console.log(`   ⚠️  Buffer muy pequeño (${photoBuffer.length} bytes), probablemente no es una imagen válida`);
                    continue;
                }



                // Subir a Cloudinary
                const cloudinaryResult = await uploadImage(
                    photoBuffer,
                    'profile_photos',
                    `user_${user.username}`
                );

                // Actualizar el documento en la base de datos
                await usersCollection.updateOne(
                    { _id: user._id },
                    {
                        $set: {
                            profilePhoto: cloudinaryResult.secure_url,
                            profilePhotoPublicId: cloudinaryResult.public_id,
                            profilePhotoBuffer: user.profilePhoto // Guardar el original
                        }
                    }
                );

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
