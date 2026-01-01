require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const logger = require('./utils/logger');
const app = express();
const PORT = process.env.PORT || 3000;
const bodyParser = require('body-parser');

// Middleware de logging HTTP
app.use(logger.httpMiddleware);

// Configurar CORS según el entorno
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['*'];

app.use(cors({
  origin: process.env.NODE_ENV === 'production' ? allowedOrigins : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: '*',
  credentials: process.env.NODE_ENV === 'production',
  optionsSuccessStatus: 200
}));

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
  app.listen(PORT, () => {
    logger.info(`Servidor ejecutándose en http://localhost:${PORT}`);
    logger.info(`Entorno: ${process.env.NODE_ENV || 'development'}`);
  });
}

// Exportar la app para los tests
module.exports = app;
