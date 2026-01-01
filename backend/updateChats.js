// Script para actualizar mensajes existentes en MongoDB y agregar campo 'read'
// Ejecutar este script con: node backend/updateChats.js

const mongoose = require('mongoose');

// Conectar a MongoDB
mongoose.connect('mongodb://localhost:27017/flutter_auth', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log('Conectado a MongoDB');
    updateChats();
}).catch(err => {
    console.error('Error conectando a MongoDB:', err);
});

async function updateChats() {
    try {
        // Listar todas las colecciones
        const collections = await mongoose.connection.db.listCollections().toArray();
        console.log('Colecciones disponibles:', collections.map(c => c.name));

        // Intentar con el nombre correcto de la colección
        const Chat = mongoose.model('Chat', new mongoose.Schema({
            users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
            messages: [{
                sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
                content: String,
                timestamp: { type: Date, default: Date.now },
                read: { type: Boolean, default: false }
            }],
            lastMessage: { type: Date, default: Date.now }
        }), 'chats'); // Especificar el nombre de la colección

        // Obtener todos los chats
        const chats = await Chat.find({});
        console.log(`Encontrados ${chats.length} chats`);

        let updated = 0;
        for (const chat of chats) {
            let needsUpdate = false;
            console.log(`\nAnalizando chat ${chat._id}`);
            console.log(`Número de mensajes: ${chat.messages.length}`);

            // Actualizar cada mensaje que no tenga el campo 'read'
            chat.messages.forEach((msg, index) => {
                console.log(`  Mensaje ${index}: read=${msg.read}, content="${msg.content}"`);
                if (msg.read === undefined) {
                    msg.read = false;
                    needsUpdate = true;
                    console.log(`    -> Actualizando mensaje ${index} con read=false`);
                }
            });

            // Agregar lastMessage si no existe
            console.log(`lastMessage: ${chat.lastMessage}`);
            if (!chat.lastMessage && chat.messages.length > 0) {
                chat.lastMessage = chat.messages[chat.messages.length - 1].timestamp;
                needsUpdate = true;
                console.log(`  -> Agregando lastMessage desde último mensaje`);
            } else if (!chat.lastMessage) {
                chat.lastMessage = new Date();
                needsUpdate = true;
                console.log(`  -> Agregando lastMessage con fecha actual`);
            }

            console.log(`needsUpdate: ${needsUpdate}`);
            if (needsUpdate) {
                await chat.save();
                updated++;
                console.log(`Chat ${chat._id} actualizado`);
            }
        }

        console.log(`Chats actualizados: ${updated}`);
        
        // Cerrar conexión
        mongoose.connection.close();
    } catch (error) {
        console.error('Error actualizando chats:', error);
        mongoose.connection.close();
    }
}
