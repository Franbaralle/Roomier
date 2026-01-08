const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
    users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    messages: [{
        sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        content: String,
        type: { type: String, enum: ['text', 'image'], default: 'text' },
        timestamp: { type: Date, default: Date.now },
        read: { type: Boolean, default: false }
    }],
    lastMessage: { type: Date, default: Date.now },
    isFirstStep: { type: Boolean, default: false }, // Indica si es un "primer paso" sin match
    firstStepBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Quién dio el primer paso
    isMatch: { type: Boolean, default: false } // Indica si es un match mutuo
});

const Chat = mongoose.model('Chat', chatSchema);

module.exports = Chat;