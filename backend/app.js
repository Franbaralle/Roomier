require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const logger = require('./utils/logger');
const { initializeFirebase } = require('./utils/firebase');
const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;
const bodyParser = require('body-parser');

// Inicializar Firebase Admin SDK
initializeFirebase();

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
const notificationsRoute = require('./routes/notifications');
const photosRoute = require('./routes/photos');
const migrateRoute = require('./routes/migrate');
const reviewRoutes = require('./routes/reviewRoutes');

app.use('/api/auth', authController);
app.use('/api/register', registerRoutes);
app.use('/api/profile', profileRoute);
app.use('/api/home', homeRoute);
app.use('/api/chat', chatRoute);
app.use('/api/moderation', moderationRoute);
app.use('/api/admin', adminRoute);
app.use('/api/edit-profile', editProfileRoute);
app.use('/api/analytics', analyticsRoute);
app.use('/api/notifications', notificationsRoute);
app.use('/api/photos', photosRoute);
app.use('/api/migrate', migrateRoute);
app.use('/api/reviews', reviewRoutes);

// Rutas de salud y raíz
app.get('/', (req, res) => {
  res.send('Servidor en funcionamiento');
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Middleware 404 debe ir AL FINAL
app.use((req, res) => {
  res.status(404).send('Página no encontrada');
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
const { sendPushNotification } = require('./utils/firebase');

// Mapa para rastrear usuarios conectados: userId -> socketId
const connectedUsers = new Map();

// Mapa para rastrear usuarios activos en chats específicos: chatId -> Set(userIds)
const activeChats = new Map();

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
    
    // Registrar usuario como activo en este chat
    if (socket.userId) {
      if (!activeChats.has(chatId)) {
        activeChats.set(chatId, new Set());
      }
      activeChats.get(chatId).add(socket.userId);
      logger.info(`Usuario ${socket.username} se unió al chat ${chatId} (activos: ${activeChats.get(chatId).size})`);
    } else {
      logger.info(`Usuario ${socket.username} se unió al chat ${chatId}`);
    }
  });

  // Usuario entra al chat (app en foreground con chat abierto)
  socket.on('enter_chat', (data) => {
    const { chatId, username } = data;
    if (socket.userId) {
      if (!activeChats.has(chatId)) {
        activeChats.set(chatId, new Set());
      }
      activeChats.get(chatId).add(socket.userId);
      logger.info(`Usuario ${username} entró al chat ${chatId} (activos: ${activeChats.get(chatId).size})`);
    }
  });

  // Usuario sale del chat
  socket.on('leave_chat', (data) => {
    const { chatId, username } = data;
    if (socket.userId && activeChats.has(chatId)) {
      activeChats.get(chatId).delete(socket.userId);
      logger.info(`Usuario ${username} salió del chat ${chatId} (activos: ${activeChats.get(chatId).size})`);
      
      // Limpiar el Set si está vacío
      if (activeChats.get(chatId).size === 0) {
        activeChats.delete(chatId);
      }
    }
  });

  // Enviar mensaje
  socket.on('send_message', async (data) => {
    try {
      const { chatId, sender, message } = data;
      
      // ====== MODERACIÓN DE CONTENIDO ======
      const { checkMessage, getSeverityLevel } = require('./utils/contentModerator');
      const moderationResult = checkMessage(message);
      
      if (!moderationResult.isClean) {
        const severity = getSeverityLevel(moderationResult.detectedWords);
        
        // Registrar intento
        console.warn(`[MODERATOR-SOCKET] Mensaje bloqueado - Sender: ${sender}, Severity: ${severity}`);
        console.warn(`[MODERATOR-SOCKET] Palabras:`, moderationResult.detectedWords);
        
        // Bloquear según severidad
        if (severity === 'critical' || severity === 'high' || severity === 'medium') {
          socket.emit('message_blocked', { 
            reason: 'Tu mensaje contiene contenido inapropiado y no puede ser enviado.',
            severity: severity
          });
          return;
        }
      }
      // ====== FIN MODERACIÓN ======
      
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

      // Enviar notificación push al otro usuario si no está viendo el chat
      const otherUser = chat.users.find(u => u.username !== sender);
      if (otherUser) {
        const otherUserData = await User.findOne({ username: otherUser.username });
        
        // Verificar si el otro usuario está actualmente viendo este chat
        const isUserActiveInChat = activeChats.has(chatId) && 
                                   activeChats.get(chatId).has(otherUserData._id.toString());
        
        // Solo enviar notificación push si:
        // 1. El usuario tiene un token FCM registrado
        // 2. El usuario NO está actualmente viendo este chat específico
        if (otherUserData.fcmToken && !isUserActiveInChat) {
          await sendPushNotification(
            otherUserData.fcmToken,
            {
              title: `Nuevo mensaje de ${sender}`,
              body: message.length > 100 ? message.substring(0, 100) + '...' : message
            },
            {
              type: 'chat_message',
              chatId: chatId,
              sender: sender
            }
          );
          logger.info(`Notificación push enviada a ${otherUser.username}`);
        } else if (isUserActiveInChat) {
          logger.info(`Usuario ${otherUser.username} está viendo el chat, no se envía notificación`);
        }
      }

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

  // Revelar información adicional
  socket.on('reveal_info', async (data) => {
    try {
      const { username, matchedUser, infoType } = data;
      logger.info(`Usuario ${username} reveló ${infoType} a ${matchedUser}`);
      
      // Encontrar el socket del otro usuario para notificarle
      const otherUserData = await User.findOne({ username: matchedUser });
      if (otherUserData && connectedUsers.has(otherUserData._id.toString())) {
        const otherSocketId = connectedUsers.get(otherUserData._id.toString());
        io.to(otherSocketId).emit('reveal_info_updated', {
          username: username,
          matchedUser: matchedUser,
          infoType: infoType
        });
        logger.info(`Notificación de reveal_info enviada a ${matchedUser}`);
      }
    } catch (error) {
      logger.error(`Error en reveal_info: ${error.message}`);
    }
  });

  // Marcar mensajes como leídos
  socket.on('mark_as_read', async (data) => {
    try {
      const { chatId, username } = data;
      const chat = await Chat.findById(chatId);
      const user = await User.findOne({ username });

      if (chat && user) {
        // Marcar todos los mensajes del otro usuario como leídos
        let updated = false;
        chat.messages.forEach(msg => {
          if (msg.sender.toString() !== user._id.toString() && !msg.read) {
            msg.read = true;
            updated = true;
          }
        });

        if (updated) {
          await chat.save();
          
          // Emitir evento para notificar al otro usuario que sus mensajes fueron leídos
          socket.to(chatId).emit('messages_read', {
            chatId,
            reader: username
          });
          
          logger.info(`Mensajes marcados como leídos en chat ${chatId} por ${username}`);
        }
      }
    } catch (error) {
      logger.error(`Error marcando mensajes como leídos: ${error.message}`);
    }
  });

  // Desconexión
  socket.on('disconnect', () => {
    if (socket.userId) {
      connectedUsers.delete(socket.userId);
      
      // Remover usuario de todos los chats activos
      activeChats.forEach((users, chatId) => {
        if (users.has(socket.userId)) {
          users.delete(socket.userId);
          logger.info(`Usuario ${socket.username} removido del chat ${chatId} por desconexión`);
          
          // Limpiar el Set si está vacío
          if (users.size === 0) {
            activeChats.delete(chatId);
          }
        }
      });
      
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
