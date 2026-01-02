const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;

async function inspectUser() {
    try {
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Conectado a MongoDB\n');

        // Obtener un usuario directamente sin el modelo
        const db = mongoose.connection.db;
        const usersCollection = db.collection('users');
        
        const user = await usersCollection.findOne({ username: 'FranBara' });
        
        if (user) {
            console.log('📝 Usuario FranBara encontrado\n');
            console.log('Estructura completa del profilePhoto:');
            console.log('=====================================');
            console.log('Tipo:', typeof user.profilePhoto);
            console.log('Es Buffer:', Buffer.isBuffer(user.profilePhoto));
            console.log('Constructor:', user.profilePhoto?.constructor?.name);
            
            if (user.profilePhoto) {
                console.log('\nContenido (primeros 100 chars):');
                console.log(user.profilePhoto.toString().substring(0, 100));
                
                console.log('\nKeys del objeto:', Object.keys(user.profilePhoto));
                
                // Si tiene buffer
                if (user.profilePhoto.buffer) {
                    console.log('\nTiene propiedad buffer:');
                    console.log('  Buffer length:', user.profilePhoto.buffer.length);
                    console.log('  Buffer type:', Buffer.isBuffer(user.profilePhoto.buffer));
                }
                
                // Ver el objeto completo
                console.log('\nObjeto completo (JSON):');
                console.log(JSON.stringify(user.profilePhoto, null, 2).substring(0, 500));
            }
        } else {
            console.log('❌ Usuario FranBara no encontrado');
        }

        process.exit(0);

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

inspectUser();
