/**
 * Script para ELIMINAR TODOS LOS USUARIOS de la base de datos
 * ⚠️  USAR CON PRECAUCIÓN - Esta acción NO es reversible
 * 
 * Ejecutar con: node clearAllUsers.js
 */

const mongoose = require('mongoose');
const User = require('./models/user');
const Chat = require('./models/chatModel');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/roomier';

async function clearAllUsers() {
    try {
        await mongoose.connect(MONGODB_URI);
        console.log('✅ Conectado a MongoDB');

        // Contar usuarios antes de borrar
        const userCount = await User.countDocuments({});
        const chatCount = await Chat.countDocuments({});

        console.log('\n⚠️  ADVERTENCIA: OPERACIÓN DESTRUCTIVA ⚠️');
        console.log('========================================');
        console.log(`📊 Total de usuarios a eliminar: ${userCount}`);
        console.log(`💬 Total de chats a eliminar: ${chatCount}`);
        console.log('========================================\n');

        // Dar tiempo para cancelar (Ctrl+C)
        console.log('⏳ Esperando 5 segundos antes de eliminar...');
        console.log('   Presiona Ctrl+C para CANCELAR\n');
        
        await new Promise(resolve => setTimeout(resolve, 5000));

        console.log('🗑️  Eliminando todos los usuarios...');
        const deletedUsers = await User.deleteMany({});
        
        console.log('🗑️  Eliminando todos los chats...');
        const deletedChats = await Chat.deleteMany({});

        console.log('\n========================================');
        console.log('✅ LIMPIEZA COMPLETADA');
        console.log('========================================');
        console.log(`🗑️  Usuarios eliminados: ${deletedUsers.deletedCount}`);
        console.log(`🗑️  Chats eliminados: ${deletedChats.deletedCount}`);
        console.log('========================================\n');

        console.log('✨ Base de datos limpia. Puedes crear usuarios nuevos con la estructura actualizada.');

    } catch (error) {
        console.error('❌ Error en la limpieza:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Desconectado de MongoDB');
    }
}

// Ejecutar limpieza
console.log('🚀 Iniciando limpieza de base de datos...\n');
clearAllUsers();
