/**
 * Script para agregar campos de "Primeros Pasos" a todos los usuarios
 * Ejecutar con: node backend/scripts/addFirstStepsToUsers.js
 */

const mongoose = require('mongoose');
const User = require('../models/user');
const path = require('path');

// Cargar .env desde backend/.env
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

async function addFirstStepsToUsers() {
  try {
    // Conectar a MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Conectado a MongoDB');

    // Buscar todos los usuarios que NO tienen el campo firstStepsRemaining
    const usersWithoutFirstSteps = await User.find({
      firstStepsRemaining: { $exists: false }
    });

    console.log(`📊 Usuarios sin campo firstStepsRemaining: ${usersWithoutFirstSteps.length}`);

    if (usersWithoutFirstSteps.length === 0) {
      console.log('✅ Todos los usuarios ya tienen los campos de primeros pasos');
      process.exit(0);
    }

    // Actualizar usuarios en lote
    const result = await User.updateMany(
      {
        firstStepsRemaining: { $exists: false }
      },
      {
        $set: {
          firstStepsRemaining: 5,
          firstStepsUsedThisWeek: 0,
          firstStepsResetDate: new Date(),
          isPremium: false
        }
      }
    );

    console.log(`✅ Actualización completada:`);
    console.log(`   - Usuarios encontrados: ${result.matchedCount}`);
    console.log(`   - Usuarios modificados: ${result.modifiedCount}`);

    // Verificar algunos usuarios aleatorios
    const updatedUsers = await User.find({
      firstStepsRemaining: { $exists: true }
    }).limit(3).select('username firstStepsRemaining isPremium');

    console.log('\n📋 Ejemplo de usuarios actualizados:');
    updatedUsers.forEach(user => {
      console.log(`   - ${user.username}: ${user.firstStepsRemaining} pasos, Premium: ${user.isPremium}`);
    });

    console.log('\n✅ Migración completada exitosamente');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error en la migración:', error);
    process.exit(1);
  }
}

// Ejecutar script
addFirstStepsToUsers();
