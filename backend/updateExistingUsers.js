const mongoose = require('mongoose');
const User = require('./models/user');

// Conectar a MongoDB
mongoose.connect('mongodb://localhost:27017/roomier', {
    useNewUrlParser: true,
    useUnifiedTopology: true
})
.then(() => console.log('Conectado a MongoDB'))
.catch(err => console.error('Error al conectar a MongoDB:', err));

async function updateExistingUsers() {
    try {
        console.log('Iniciando actualización de usuarios existentes...');

        // Obtener todos los usuarios
        const users = await User.find({});
        console.log(`Encontrados ${users.length} usuarios para actualizar`);

        let updatedCount = 0;

        for (const user of users) {
            let needsUpdate = false;

            // Agregar livingHabits si no existe
            if (!user.livingHabits) {
                user.livingHabits = {
                    smoker: false,
                    hasPets: false,
                    acceptsPets: false,
                    cleanliness: 'normal',
                    noiseLevel: 'normal',
                    schedule: 'normal',
                    socialLevel: 'friendly',
                    hasGuests: false,
                    drinker: 'social'
                };
                needsUpdate = true;
            }

            // Agregar housingInfo si no existe
            if (!user.housingInfo) {
                user.housingInfo = {
                    budgetMin: 0,
                    budgetMax: 0,
                    preferredZones: [],
                    hasPlace: false,
                    moveInDate: '',
                    stayDuration: '6months',
                    city: '',
                    generalZone: ''
                };
                needsUpdate = true;
            }

            // Agregar dealBreakers si no existe
            if (!user.dealBreakers) {
                user.dealBreakers = {
                    noSmokers: false,
                    noPets: false,
                    noParties: false,
                    noChildren: false
                };
                needsUpdate = true;
            }

            // Migrar campos de verificación al nuevo formato
            if (!user.verification) {
                user.verification = {
                    emailVerified: user.isVerified || false,
                    phoneNumber: '',
                    phoneVerified: false,
                    idVerified: false,
                    selfieVerified: false,
                    verificationCode: user.verificationCode || ''
                };
                needsUpdate = true;
            }

            // Agregar revealedInfo si no existe
            if (!user.revealedInfo) {
                user.revealedInfo = [];
                needsUpdate = true;
            }

            // Agregar reportedBy si no existe
            if (!user.reportedBy) {
                user.reportedBy = [];
                needsUpdate = true;
            }

            // Agregar blockedUsers si no existe
            if (!user.blockedUsers) {
                user.blockedUsers = [];
                needsUpdate = true;
            }

            // Agregar timestamps si no existen
            if (!user.createdAt) {
                user.createdAt = new Date();
                needsUpdate = true;
            }

            if (!user.lastActive) {
                user.lastActive = new Date();
                needsUpdate = true;
            }

            if (needsUpdate) {
                await user.save();
                updatedCount++;
                console.log(`✓ Usuario actualizado: ${user.username}`);
            } else {
                console.log(`- Usuario ya actualizado: ${user.username}`);
            }
        }

        console.log(`\n✅ Actualización completada!`);
        console.log(`Usuarios actualizados: ${updatedCount}`);
        console.log(`Usuarios sin cambios: ${users.length - updatedCount}`);

        process.exit(0);
    } catch (error) {
        console.error('❌ Error durante la actualización:', error);
        process.exit(1);
    }
}

// Ejecutar la actualización
updateExistingUsers();
