const mongoose = require('mongoose');
const User = require('./models/user');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/roomier';

async function checkUsers() {
    try {
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Conectado a MongoDB');

        // Contar todos los usuarios
        const totalUsers = await User.countDocuments({});
        console.log(`\n📊 Total de usuarios: ${totalUsers}`);

        // Usuarios con profilePhoto (cualquier tipo)
        const usersWithPhoto = await User.countDocuments({
            profilePhoto: { $exists: true, $ne: null }
        });
        console.log(`📸 Usuarios con profilePhoto: ${usersWithPhoto}`);

        // Usuarios con profilePhotoPublicId (migrados a Cloudinary)
        const usersWithPublicId = await User.countDocuments({
            profilePhotoPublicId: { $exists: true, $ne: null }
        });
        console.log(`☁️  Usuarios migrados a Cloudinary: ${usersWithPublicId}`);

        // Usuarios pendientes de migración
        const usersPendingMigration = await User.countDocuments({
            profilePhoto: { $exists: true, $ne: null },
            $or: [
                { profilePhotoPublicId: { $exists: false } },
                { profilePhotoPublicId: null }
            ]
        });
        console.log(`⏳ Usuarios pendientes de migración: ${usersPendingMigration}`);

        // Obtener un ejemplo de usuario con foto
        const sampleUser = await User.findOne({
            profilePhoto: { $exists: true, $ne: null }
        }).select('username profilePhoto profilePhotoPublicId');

        if (sampleUser) {
            console.log('\n📝 Ejemplo de usuario:');
            console.log(`   Username: ${sampleUser.username}`);
            console.log(`   profilePhoto tipo: ${typeof sampleUser.profilePhoto}`);
            console.log(`   profilePhoto es Buffer: ${Buffer.isBuffer(sampleUser.profilePhoto)}`);
            console.log(`   profilePhotoPublicId: ${sampleUser.profilePhotoPublicId || 'N/A'}`);
            
            if (typeof sampleUser.profilePhoto === 'object' && sampleUser.profilePhoto !== null) {
                console.log(`   profilePhoto keys: ${Object.keys(sampleUser.profilePhoto).join(', ')}`);
            }
            
            if (typeof sampleUser.profilePhoto === 'string') {
                console.log(`   profilePhoto (primeros 50 chars): ${sampleUser.profilePhoto.substring(0, 50)}...`);
            }
        }

        process.exit(0);

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

checkUsers();
