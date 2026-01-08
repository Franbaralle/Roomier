/**
 * Script para normalizar datos de usuarios
 * - Elimina campos obsoletos (profilePhotoBuffer, profilePhotoPublicId)
 * - Agrega campos faltantes con valores por defecto
 * - Limpia estructuras de datos
 * 
 * Ejecutar con: node backend/scripts/normalizeUserData.js
 */

const mongoose = require('mongoose');
const User = require('../models/user');
const path = require('path');

// Cargar .env desde backend/.env
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

async function normalizeUserData() {
  try {
    // Conectar a MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Conectado a MongoDB');

    const allUsers = await User.find({});
    console.log(`📊 Total de usuarios a normalizar: ${allUsers.length}\n`);

    let updatedCount = 0;
    let issues = [];

    for (const user of allUsers) {
      let needsUpdate = false;
      const updates = {};
      const unsetFields = {};

      // 1. Eliminar campos obsoletos
      if (user.profilePhotoBuffer) {
        unsetFields.profilePhotoBuffer = '';
        needsUpdate = true;
        console.log(`🗑️  ${user.username}: Eliminando profilePhotoBuffer`);
      }

      if (user.profilePhotoPublicId) {
        unsetFields.profilePhotoPublicId = '';
        needsUpdate = true;
        console.log(`🗑️  ${user.username}: Eliminando profilePhotoPublicId`);
      }

      // 2. Agregar personalInfo si no existe
      if (!user.personalInfo) {
        updates.personalInfo = {
          aboutMe: '',
          job: '',
          politicPreference: '',
          religion: ''
        };
        needsUpdate = true;
        console.log(`➕ ${user.username}: Agregando personalInfo`);
      }

      // 3. Asegurar roommatePreferences
      if (!user.roommatePreferences) {
        updates.roommatePreferences = {
          gender: 'both',
          ageMin: 18,
          ageMax: 99
        };
        needsUpdate = true;
        console.log(`➕ ${user.username}: Agregando roommatePreferences`);
      } else if (!user.roommatePreferences.ageMin || !user.roommatePreferences.ageMax) {
        updates['roommatePreferences.ageMin'] = user.roommatePreferences.ageMin || 18;
        updates['roommatePreferences.ageMax'] = user.roommatePreferences.ageMax || 99;
        needsUpdate = true;
        console.log(`➕ ${user.username}: Agregando ageMin/ageMax`);
      }

      // 4. Asegurar arrays existen
      if (!user.profilePhotos) {
        updates.profilePhotos = [];
        needsUpdate = true;
      }
      if (!user.homePhotos) {
        updates.homePhotos = [];
        needsUpdate = true;
      }
      if (!user.legacyPreferences) {
        updates.legacyPreferences = [];
        needsUpdate = true;
      }
      if (!user.revealedInfo) {
        updates.revealedInfo = [];
        needsUpdate = true;
      }

      // 5. Validar estructura de preferences
      const requiredCategories = [
        'convivencia',
        'gastronomia',
        'deporte',
        'entretenimiento',
        'creatividad',
        'interesesSociales'
      ];

      if (!user.preferences) {
        updates.preferences = {};
        needsUpdate = true;
      }

      for (const category of requiredCategories) {
        if (!user.preferences?.[category]) {
          updates[`preferences.${category}`] = {};
          needsUpdate = true;
        }
      }

      // 6. Validar dealBreakers
      if (!user.dealBreakers) {
        updates.dealBreakers = {
          noSmokers: false,
          noPets: false,
          noParties: false,
          noChildren: false
        };
        needsUpdate = true;
        console.log(`➕ ${user.username}: Agregando dealBreakers`);
      }

      // 7. Validar verification
      if (!user.verification) {
        updates.verification = {
          emailVerified: false,
          phoneVerified: false,
          idVerified: false,
          selfieVerified: false
        };
        needsUpdate = true;
      }

      // 8. Detectar problemas que requieren atención manual
      if (!user.profilePhoto) {
        issues.push(`⚠️  ${user.username}: Sin foto de perfil`);
      }
      if (!user.gender) {
        issues.push(`⚠️  ${user.username}: Sin género definido`);
      }

      // Aplicar actualizaciones
      if (needsUpdate) {
        const updateQuery = {};
        if (Object.keys(updates).length > 0) {
          updateQuery.$set = updates;
        }
        if (Object.keys(unsetFields).length > 0) {
          updateQuery.$unset = unsetFields;
        }

        await User.updateOne({ _id: user._id }, updateQuery);
        updatedCount++;
      }
    }

    console.log(`\n✅ Normalización completada:`);
    console.log(`   - Usuarios procesados: ${allUsers.length}`);
    console.log(`   - Usuarios actualizados: ${updatedCount}`);

    if (issues.length > 0) {
      console.log(`\n⚠️  Problemas detectados (requieren atención manual):`);
      issues.forEach(issue => console.log(`   ${issue}`));
    }

    // Verificar resultado
    const sampleUsers = await User.find({}).limit(3).select('username personalInfo roommatePreferences profilePhotos homePhotos');
    console.log('\n📋 Ejemplo de usuarios normalizados:');
    sampleUsers.forEach(user => {
      console.log(`\n   Usuario: ${user.username}`);
      console.log(`   - personalInfo: ${user.personalInfo ? '✅' : '❌'}`);
      console.log(`   - roommatePreferences: ${user.roommatePreferences ? '✅' : '❌'}`);
      console.log(`   - profilePhotos: ${Array.isArray(user.profilePhotos) ? '✅' : '❌'}`);
      console.log(`   - homePhotos: ${Array.isArray(user.homePhotos) ? '✅' : '❌'}`);
    });

    console.log('\n✅ Script completado exitosamente');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error en la normalización:', error);
    process.exit(1);
  }
}

// Ejecutar script
normalizeUserData();
