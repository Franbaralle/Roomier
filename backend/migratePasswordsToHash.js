// Script para migrar contraseñas existentes a bcrypt hash
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./models/user');

async function migratePasswords() {
    try {
        // Conectar a MongoDB
        await mongoose.connect('mongodb://127.0.0.1:27017/roomier');
        console.log('Conectado a MongoDB');

        // Obtener todos los usuarios
        const users = await User.find({});
        console.log(`Encontrados ${users.length} usuarios`);

        let migrated = 0;
        let alreadyHashed = 0;

        for (const user of users) {
            // Verificar si la contraseña ya está hasheada
            // Las contraseñas hasheadas con bcrypt comienzan con "$2b$" o "$2a$"
            if (user.password && !user.password.startsWith('$2')) {
                console.log(`Migrando contraseña para usuario: ${user.username}`);
                
                // Hashear la contraseña
                const hashedPassword = await bcrypt.hash(user.password, 10);
                user.password = hashedPassword;
                await user.save();
                
                migrated++;
            } else {
                console.log(`Usuario ${user.username} ya tiene contraseña hasheada`);
                alreadyHashed++;
            }
        }

        console.log('\n=== Resumen de Migración ===');
        console.log(`Total de usuarios: ${users.length}`);
        console.log(`Contraseñas migradas: ${migrated}`);
        console.log(`Ya hasheadas: ${alreadyHashed}`);
        console.log('Migración completada exitosamente');

        process.exit(0);
    } catch (error) {
        console.error('Error durante la migración:', error);
        process.exit(1);
    }
}

migratePasswords();
