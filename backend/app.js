require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const logger = require('./utils/logger');
const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;
const bodyParser = require('body-parser');

// Confiar en proxy (necesario para Railway, Heroku, etc.)
app.set('trust proxy', true);

// Middleware de logging HTTP
app.use(logger.httpMiddleware);

// Configurar CORS según el entorno
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['*'];

const corsOptions = {
  origin: process.env.NODE_ENV === 'production' ? allowedOrigins : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: '*',
  credentials: process.env.NODE_ENV === 'production',
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

// Configurar Socket.IO con CORS
const io = socketIo(server, {
  cors: corsOptions,
  transports: ['websocket', 'polling']
});

app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({limit: '50mb', extended: true}));
app.use(express.json());

// Usar variable de entorno para MongoDB
const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/flutter_auth';
mongoose.connect(mongoUri);

const db = mongoose.connection;
db.on('error', (error) => logger.error(`MongoDB connection error: ${error.message}`));
db.once('open', () => {
  logger.info('Conexión a MongoDB establecida con éxito');
});

const registerRoutes = require('./routes/register');
const authController = require('./controllers/authController');
const profileRoute = require('./routes/profile');
const homeRoute = require('./routes/home');
const chatRoute = require('./routes/chat');
const moderationRoute = require('./routes/moderation');
const adminRoute = require('./routes/admin');
const editProfileRoute = require('./routes/editProfile');
const analyticsRoute = require('./routes/analytics');

app.use('/api/auth', authController);
app.use('/api/register', registerRoutes);
app.use('/api/profile', profileRoute);
app.use('/api/home', homeRoute);
app.use('/api/chat', chatRoute);
app.use('/api/moderation', moderationRoute);
app.use('/api/admin', adminRoute);
app.use('/api/edit-profile', editProfileRoute);
app.use('/api/analytics', analyticsRoute);

app.use((req, res) => {
  res.status(404).send('Página no encontrada');
});

app.get('/', (req, res) => {
  res.send('Servidor en funcionamiento');
});

// Manejador de errores global
app.use((err, req, res, next) => {
  logger.error(`Error: ${err.message}`, { stack: err.stack });
  res.status(500).json({ error: 'Error interno del servidor' });
});

// Solo iniciar el servidor si no estamos en modo test
if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT, () => {
    logger.info(`Servidor ejecutándose en http://localhost:${PORT}`);
    logger.info(`Entorno: ${process.env.NODE_ENV || 'development'}`);
  });
}

// Configuración de Socket.IO
const Chat = require('./models/chatModel');
const User = require('./models/user');

// Mapa para rastrear usuarios conectados: userId -> socketId
const connectedUsers = new Map();

io.on('connection', (socket) => {
  logger.info(`Cliente conectado: ${socket.id}`);

  // Registrar usuario cuando se conecta
  socket.on('register', async (username) => {
    try {
      const user = await User.findOne({ username });
      if (user) {
        connectedUsers.set(user._id.toString(), socket.id);
        socket.userId = user._id.toString();
        socket.username = username;
        logger.info(`Usuario registrado: ${username} (${socket.id})`);
      }
    } catch (error) {
      logger.error(`Error registrando usuario: ${error.message}`);
    }
  });

  // Unirse a una sala de chat específica
  socket.on('join_chat', (chatId) => {
    socket.join(chatId);
    logger.info(`Usuario ${socket.username} se unió al chat ${chatId}`);
  });

  // Enviar mensaje
  socket.on('send_message', async (data) => {
    try {
      const { chatId, sender, message } = data;
      
      // Buscar el chat y el usuario
      const chat = await Chat.findById(chatId).populate('users', 'username');
      const user = await User.findOne({ username: sender });

      if (!chat || !user) {
        socket.emit('error', { message: 'Chat o usuario no encontrado' });
        return;
      }

      // Agregar el mensaje al chat
      const newMessage = {
        sender: user._id,
        content: message,
        read: false,
        timestamp: new Date()
      };

      chat.messages.push(newMessage);
      chat.lastMessage = new Date();
      await chat.save();

      // Emitir el mensaje a todos en la sala del chat
      io.to(chatId).emit('receive_message', {
        chatId,
        message: {
          ...newMessage,
          sender: { username: sender, _id: user._id }
        }
      });

      logger.info(`Mensaje enviado en chat ${chatId} por ${sender}`);
    } catch (error) {
      logger.error(`Error enviando mensaje: ${error.message}`);
      socket.emit('error', { message: 'Error al enviar mensaje' });
    }
  });

  // Usuario escribiendo
  socket.on('typing', (data) => {
    const { chatId, username } = data;
    socket.to(chatId).emit('user_typing', { chatId, username });
  });

  // Usuario dejó de escribir
  socket.on('stop_typing', (data) => {
    const { chatId, username } = data;
    socket.to(chatId).emit('user_stop_typing', { chatId, username });
  });

  // Marcar mensajes como leídos
  socket.on('mark_as_read', async (data) => {
    try {
      const { chatId, username } = data;
      const chat = await Chat.findById(chatId);
      const user = await User.findOne({ username });

      if (chat && user) {
        // Marcar todos los mensajes del otro usuario como leídos
        chat.messages.forEach(msg => {
          if (msg.sender.toString() !== user._id.toString()) {
            msg.read = true;
          }
        });
        await chat.save();

        // Notificar al otro usuario que sus mensajes fueron leídos
        io.to(chatId).emit('messages_read', { chatId, username });
      }
    } catch (error) {
      logger.error(`Error marcando mensajes como leídos: ${error.message}`);
    }
  });

  // Desconexión
  socket.on('disconnect', () => {
    if (socket.userId) {
      connectedUsers.delete(socket.userId);
      logger.info(`Usuario desconectado: ${socket.username} (${socket.id})`);
    } else {
      logger.info(`Cliente desconectado: ${socket.id}`);
    }
  });
});

// Exportar io para usar en otros módulos si es necesario
app.set('io', io);

// Exportar la app para los tests
module.exports = app;
