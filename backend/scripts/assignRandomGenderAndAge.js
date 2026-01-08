/**
 * Script para asignar género y rango de edad aleatorios a usuarios existentes
 * 
 * Ejecución:
 * node backend/scripts/assignRandomGenderAndAge.js
 * 
 * Este script:
 * 1. Busca usuarios sin género asignado
 * 2. Asigna género aleatorio: "Hombre" o "Mujer" (50/50)
 * 3. Busca usuarios sin rango de edad en roommatePreferences
 * 4. Asigna rango de edad aleatorio (ej: 18-30, 22-32, 25-35, etc.)
 */

const mongoose = require('mongoose');
const path = require('path');

// Cargar variables de entorno
const envPath = path.resolve(__dirname, '../.env');
console.log('Cargando .env desde:', envPath);
require('dotenv').config({ path: envPath });

// Verificar que MONGODB_URI esté cargado
if (!process.env.MONGODB_URI) {
    console.error('❌ ERROR: MONGODB_URI no encontrado en las variables de entorno');
    console.log('Variables disponibles:', Object.keys(process.env).filter(k => !k.startsWith('npm_')).slice(0, 10));
    process.exit(1);
}

// Importar modelo de Usuario
const User = require('../models/user');

// Opciones de género en inglés (50% male, 50% female)
const GENDERS = ['male', 'female'];

// Función para obtener género aleatorio
function getRandomGender() {
    return GENDERS[Math.floor(Math.random() * GENDERS.length)];
}

// Función para obtener rango de edad aleatorio
function getRandomAgeRange() {
    // Rangos típicos de búsqueda
    const baseAges = [18, 20, 22, 25, 28, 30, 35, 40, 45];
    const baseAge = baseAges[Math.floor(Math.random() * baseAges.length)];
    
    // Rango de +/- 5 a 10 años
    const rangeSize = Math.floor(Math.random() * 6) + 5; // Entre 5 y 10 años
    
    return {
        ageMin: baseAge,
        ageMax: Math.min(baseAge + rangeSize, 99) // Máximo 99
    };
}

async function assignRandomGenderAndAge() {
    try {
        // Conectar a MongoDB
        console.log('🔌 Conectando a MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Conectado a MongoDB');

        // ==========================================
        // PASO 1: Asignar género aleatorio
        // ==========================================
        console.log('\n📍 PASO 1: Buscando usuarios sin género...');
        
        const usersWithoutGender = await User.find({
            $or: [
                { gender: { $exists: false } },
                { gender: null },
                { gender: '' }
            ]
        });

        console.log(`   Encontrados: ${usersWithoutGender.length} usuarios sin género`);

        if (usersWithoutGender.length > 0) {
            console.log('\n🎲 Asignando género aleatorio...');
            
            let updatedGenderCount = 0;
            
            for (const user of usersWithoutGender) {
                const randomGender = getRandomGender();
                user.gender = randomGender;
                await user.save();
                updatedGenderCount++;
                
                console.log(`   ✓ ${user.username}: ${randomGender}`);
            }
            
            console.log(`\n✅ Género asignado a ${updatedGenderCount} usuarios`);
        } else {
            console.log('   ℹ️  Todos los usuarios ya tienen género asignado');
        }

        // ==========================================
        // PASO 2: Asignar rango de edad aleatorio
        // ==========================================
        console.log('\n📍 PASO 2: Buscando usuarios sin rango de edad...');
        
        const usersWithoutAgeRange = await User.find({
            $or: [
                { 'roommatePreferences.ageMin': { $exists: false } },
                { 'roommatePreferences.ageMax': { $exists: false } },
                { 'roommatePreferences.ageMin': null },
                { 'roommatePreferences.ageMax': null }
            ]
        });

        console.log(`   Encontrados: ${usersWithoutAgeRange.length} usuarios sin rango de edad`);

        if (usersWithoutAgeRange.length > 0) {
            console.log('\n🎲 Asignando rango de edad aleatorio...');
            
            let updatedAgeCount = 0;
            
            for (const user of usersWithoutAgeRange) {
                const { ageMin, ageMax } = getRandomAgeRange();
                
                // Inicializar roommatePreferences si no existe
                if (!user.roommatePreferences) {
                    user.roommatePreferences = {
                        gender: 'both',
                        ageMin: ageMin,
                        ageMax: ageMax
                    };
                } else {
                    user.roommatePreferences.ageMin = ageMin;
                    user.roommatePreferences.ageMax = ageMax;
                }
                
                await user.save();
                updatedAgeCount++;
                
                console.log(`   ✓ ${user.username}: ${ageMin}-${ageMax} años`);
            }
            
            console.log(`\n✅ Rango de edad asignado a ${updatedAgeCount} usuarios`);
        } else {
            console.log('   ℹ️  Todos los usuarios ya tienen rango de edad asignado');
        }

        // ==========================================
        // RESUMEN FINAL
        // ==========================================
        console.log('\n' + '='.repeat(60));
        console.log('📊 RESUMEN DE ACTUALIZACIÓN');
        console.log('='.repeat(60));
        
        const allUsers = await User.find({});
        
        // Contar por género
        const menCount = await User.countDocuments({ gender: 'Hombre' });
        const womenCount = await User.countDocuments({ gender: 'Mujer' });
        const otherGenderCount = await User.countDocuments({ 
            gender: { $nin: ['Hombre', 'Mujer', null, ''] } 
        });
        const noGenderCount = await User.countDocuments({ 
            $or: [{ gender: null }, { gender: '' }, { gender: { $exists: false } }] 
        });
        
        console.log('\nDistribución de género:');
        console.log(`   🚹 Hombres: ${menCount}`);
        console.log(`   🚺 Mujeres: ${womenCount}`);
        if (otherGenderCount > 0) {
            console.log(`   ⚧  Otro: ${otherGenderCount}`);
        }
        if (noGenderCount > 0) {
            console.log(`   ❓ Sin género: ${noGenderCount}`);
        }
        
        // Contar con rango de edad
        const withAgeRangeCount = await User.countDocuments({
            'roommatePreferences.ageMin': { $exists: true, $ne: null },
            'roommatePreferences.ageMax': { $exists: true, $ne: null }
        });
        
        console.log('\nRango de edad:');
        console.log(`   ✅ Con rango: ${withAgeRangeCount}`);
        console.log(`   ❌ Sin rango: ${allUsers.length - withAgeRangeCount}`);
        
        // Mostrar muestra de 5 usuarios
        console.log('\n' + '='.repeat(60));
        console.log('📋 MUESTRA DE USUARIOS ACTUALIZADOS (primeros 5)');
        console.log('='.repeat(60));
        
        const sampleUsers = await User.find({}).limit(5);
        
        for (const user of sampleUsers) {
            console.log(`\n👤 ${user.username}`);
            console.log(`   Género: ${user.gender || 'No definido'}`);
            console.log(`   Rango de edad preferido: ${user.roommatePreferences?.ageMin || '?'}-${user.roommatePreferences?.ageMax || '?'} años`);
            console.log(`   Género preferido roommate: ${user.roommatePreferences?.gender || 'No definido'}`);
        }
        
        console.log('\n✅ Script completado exitosamente\n');

    } catch (error) {
        console.error('\n❌ Error en el script:', error);
        console.error(error.stack);
    } finally {
        // Cerrar conexión
        await mongoose.connection.close();
        console.log('🔌 Conexión cerrada');
        process.exit(0);
    }
}

// Ejecutar script
console.log('═══════════════════════════════════════════════════════════');
console.log('   ASIGNAR GÉNERO Y RANGO DE EDAD ALEATORIOS');
console.log('═══════════════════════════════════════════════════════════\n');

assignRandomGenderAndAge();
