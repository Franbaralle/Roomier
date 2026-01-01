const mongoose = require('mongoose');
const User = require('./models/user');
const logger = require('./utils/logger');

// Conectar a MongoDB
mongoose.connect('mongodb://127.0.0.1:27017/flutter_auth', {
    useNewUrlParser: true,
    useUnifiedTopology: true
})
.then(() => logger.info('Conectado a MongoDB'))
.catch(err => logger.error(`Error conectando a MongoDB: ${err.message}`));

/**
 * Hacer admin a un usuario existente
 * Uso: node makeAdmin.js <username>
 */
async function makeAdmin(username) {
    try {
        if (!username) {
            console.log('❌ Error: Debes proporcionar un username');
            console.log('Uso: node makeAdmin.js <username>');
            process.exit(1);
        }

        // Buscar el usuario
        const user = await User.findOne({ username });

        if (!user) {
            console.log(`❌ Error: Usuario "${username}" no encontrado`);
            console.log('\nUsuarios disponibles:');
            const allUsers = await User.find({}).select('username email');
            allUsers.forEach(u => console.log(`  - ${u.username} (${u.email})`));
            process.exit(1);
        }

        // Verificar si ya es admin
        if (user.isAdmin) {
            console.log(`ℹ️  El usuario "${username}" ya es administrador`);
            process.exit(0);
        }

        // Hacer admin
        user.isAdmin = true;
        await user.save();

        console.log(`✅ Usuario "${username}" ahora es administrador`);
        console.log(`📧 Email: ${user.email}`);
        console.log(`📅 Cuenta creada: ${user.createdAt}`);
        
        logger.info(`User ${username} granted admin privileges`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        logger.error(`Error making user admin: ${error.message}`);
        process.exit(1);
    }
}

/**
 * Remover permisos de admin
 * Uso: node makeAdmin.js <username> --remove
 */
async function removeAdmin(username) {
    try {
        const user = await User.findOne({ username });

        if (!user) {
            console.log(`❌ Error: Usuario "${username}" no encontrado`);
            process.exit(1);
        }

        if (!user.isAdmin) {
            console.log(`ℹ️  El usuario "${username}" no es administrador`);
            process.exit(0);
        }

        user.isAdmin = false;
        await user.save();

        console.log(`✅ Permisos de administrador removidos de "${username}"`);
        logger.info(`Admin privileges removed from user ${username}`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        logger.error(`Error removing admin privileges: ${error.message}`);
        process.exit(1);
    }
}

/**
 * Listar todos los administradores
 */
async function listAdmins() {
    try {
        const admins = await User.find({ isAdmin: true }).select('username email createdAt');

        if (admins.length === 0) {
            console.log('ℹ️  No hay administradores registrados');
            process.exit(0);
        }

        console.log(`\n👥 Administradores (${admins.length}):\n`);
        admins.forEach(admin => {
            console.log(`  🔑 ${admin.username}`);
            console.log(`     📧 ${admin.email}`);
            console.log(`     📅 Desde: ${admin.createdAt.toLocaleDateString()}`);
            console.log('');
        });

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

// Procesar argumentos de línea de comandos
const args = process.argv.slice(2);

if (args.length === 0) {
    console.log('📋 Uso del script makeAdmin.js:\n');
    console.log('  Hacer admin a un usuario:');
    console.log('    node makeAdmin.js <username>');
    console.log('');
    console.log('  Remover permisos de admin:');
    console.log('    node makeAdmin.js <username> --remove');
    console.log('');
    console.log('  Listar administradores:');
    console.log('    node makeAdmin.js --list');
    console.log('');
    process.exit(0);
}

if (args[0] === '--list' || args[0] === '-l') {
    listAdmins();
} else if (args.length >= 2 && (args[1] === '--remove' || args[1] === '-r')) {
    removeAdmin(args[0]);
} else {
    makeAdmin(args[0]);
}
