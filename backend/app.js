const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;
const bodyParser = require('body-parser');

app.use(bodyParser.json({limit: '50mb'}));
app.use(bodyParser.urlencoded({limit: '50mb', extended: true}));
app.use(cors());
app.use(express.json());

mongoose.connect('mongodb://127.0.0.1:27017/flutter_auth', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => {
  console.log('Conexion a MongoDB establecida con exito');
});

const registerRoutes = require('./routes/register');
const authController = require('./controllers/authController');
const profileRoute = require('./routes/profile');
const homeRoute = require('./routes/home');
app.use('/api/auth', authController);
app.use('/api/register', registerRoutes);
app.use('/api/profile', profileRoute);
app.use('/api/home', homeRoute);

app.use((req, res) => {
  res.status(404).send('Página no encontrada');
});

app.get('/', (req, res) => {
  res.send('¡Hola, mundo!');
});

app.listen(PORT, () => {
  console.log(`El servidor se está ejecutando en http://localhost:${PORT}`);
});
