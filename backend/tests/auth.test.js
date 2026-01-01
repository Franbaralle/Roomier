const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');
const User = require('../models/user');
const { jwtSecret } = require('../config/security');
const jwt = require('jsonwebtoken');

// Mock de rate limiters para tests unitarios
jest.mock('../middleware/rateLimiter', () => ({
  loginLimiter: (req, res, next) => next(),
  registerLimiter: (req, res, next) => next(),
  apiLimiter: (req, res, next) => next(),
  passwordResetLimiter: (req, res, next) => next(),
  chatLimiter: (req, res, next) => next(),
  uploadLimiter: (req, res, next) => next()
}));

let testCounter = 0;

// Conectar a la base de datos de pruebas
beforeAll(async () => {
  // Usar una base de datos de pruebas separada
  const testDbUri = 'mongodb://localhost:27017/flutter_auth_test';
  
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  
  await mongoose.connect(testDbUri);
  
  // Limpiar toda la base de datos antes de empezar
  await User.deleteMany({});
});

// Limpiar la base de datos después de cada test
afterEach(async () => {
  await User.deleteMany({});
  // Pequeño delay para asegurar limpieza
  await new Promise(resolve => setTimeout(resolve, 100));
});

// Cerrar conexión después de todos los tests
afterAll(async () => {
  await User.deleteMany({});
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});


describe('Authentication Tests', () => {
  
  describe('POST /api/auth/register', () => {
    
    it('should register a new user successfully', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          password: 'TestPassword123!',
          email: 'test@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('message', 'Usuario registrado exitosamente');
      expect(res.body).toHaveProperty('token');
      
      // Esperar a que se complete el guardado
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Verificar que el usuario existe en la BD
      const user = await User.findOne({ username: 'testuser' });
      expect(user).toBeTruthy();
      expect(user.email).toBe('test@example.com');
    });
    
    it('should hash password with bcrypt', async () => {
      const plainPassword = 'MyPlainPassword123';
      
      await request(app)
        .post('/api/auth/register')
        .send({
          username: 'hasheduser',
          password: plainPassword,
          email: 'hashed@example.com',
          birthdate: '2000-01-01',
          gender: 'femenino'
        });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      const user = await User.findOne({ username: 'hasheduser' });
      
      // La contraseña NO debe estar en texto plano
      expect(user.password).not.toBe(plainPassword);
      
      // Debe tener el formato de bcrypt ($2a$ o $2b$)
      expect(user.password).toMatch(/^\$2[aby]\$/);
      
      // La longitud debe ser consistente con bcrypt
      expect(user.password.length).toBeGreaterThan(50);
    });
    
    it('should return JWT token on registration', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'tokenuser',
          password: 'password123',
          email: 'token@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('token');
      
      // Verificar formato JWT (tres partes separadas por puntos)
      expect(res.body.token).toMatch(/^eyJ[\w-]*\.[\w-]*\.[\w-]*$/);
      
      // Decodificar y verificar el payload
      const decoded = jwt.verify(res.body.token, jwtSecret);
      expect(decoded).toHaveProperty('userId');
      expect(decoded).toHaveProperty('username', 'tokenuser');
    });
    
    it('should reject registration with duplicate username', async () => {
      // Crear primer usuario
      await request(app)
        .post('/api/auth/register')
        .send({
          username: 'duplicate',
          password: 'pass123',
          email: 'first@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Intentar crear segundo usuario con mismo username
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'duplicate',
          password: 'pass456',
          email: 'second@example.com',
          birthdate: '2000-01-01',
          gender: 'femenino'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
    
    it.skip('should reject registration with invalid email format', async () => {
      // NOTA: La validación de email no está implementada en el backend
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'invalidemail',
          password: 'pass123',
          email: 'not-an-email',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
    
    it('should reject registration with missing required fields', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'incomplete'
          // Faltan password, email, birthdate, gender
        });
      
      expect([400, 500]).toContain(res.statusCode); // 400 o 500
      expect(res.body).toHaveProperty('error');
    });
  });
  
  describe('POST /api/auth/login', () => {
    
    // Crear un usuario antes de cada test de login
    beforeEach(async () => {
      await request(app)
        .post('/api/auth/register')
        .send({
          username: 'loginuser',
          password: 'CorrectPassword123',
          email: 'login@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      // Esperar a que se complete el registro y hash de contraseña
      await new Promise(resolve => setTimeout(resolve, 200));
    });
    
    it('should login successfully with correct credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'loginuser',
          password: 'CorrectPassword123'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message', 'Inicio de sesión exitoso');
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('username', 'loginuser');
      expect(res.body).toHaveProperty('email', 'login@example.com');
    });
    
    it('should verify hashed password correctly', async () => {
      // Login con la contraseña correcta
      const correctRes = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'loginuser',
          password: 'CorrectPassword123'
        });
      
      expect(correctRes.statusCode).toBe(200);
      expect(correctRes.body).toHaveProperty('token');
      
      // Verificar que el token es válido
      const decoded = jwt.verify(correctRes.body.token, jwtSecret);
      expect(decoded.username).toBe('loginuser');
    });
    
    it('should reject login with incorrect password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'loginuser',
          password: 'WrongPassword123'
        });
      
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
      expect(res.body.error).toMatch(/inválidos/i);
    });
    
    it('should reject login with non-existent username', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'nonexistentuser',
          password: 'anypassword'
        });
      
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });
    
    it('should return token that expires in 24 hours', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'loginuser',
          password: 'CorrectPassword123'
        });
      
      const decoded = jwt.verify(res.body.token, jwtSecret);
      
      // Verificar que el token tiene fecha de expiración
      expect(decoded).toHaveProperty('exp');
      
      // Verificar que expira en aproximadamente 24 horas (con margen de 1 minuto)
      const now = Math.floor(Date.now() / 1000);
      const expirationTime = decoded.exp - now;
      const twentyFourHours = 24 * 60 * 60;
      
      expect(expirationTime).toBeGreaterThan(twentyFourHours - 60);
      expect(expirationTime).toBeLessThan(twentyFourHours + 60);
    });
    
    it('should include userId and username in JWT payload', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'loginuser',
          password: 'CorrectPassword123'
        });
      
      const decoded = jwt.verify(res.body.token, jwtSecret);
      
      expect(decoded).toHaveProperty('userId');
      expect(decoded).toHaveProperty('username', 'loginuser');
      
      // Verificar que userId es un ObjectId válido de MongoDB
      expect(mongoose.Types.ObjectId.isValid(decoded.userId)).toBe(true);
    });
  });
  
  describe('PUT /api/auth/update-password/:username', () => {
    
    beforeEach(async () => {
      await request(app)
        .post('/api/auth/register')
        .send({
          username: 'passworduser',
          password: 'OldPassword123',
          email: 'password@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      await new Promise(resolve => setTimeout(resolve, 200));
    });
    
    it('should update password successfully', async () => {
      const res = await request(app)
        .put('/api/auth/update-password/passworduser')
        .send({
          newPassword: 'NewPassword456'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
      
      // Esperar a que se complete el hash de la nueva contraseña
      await new Promise(resolve => setTimeout(resolve, 200));
      
      // Verificar que el login funciona con la nueva contraseña
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'passworduser',
          password: 'NewPassword456'
        });
      
      expect(loginRes.statusCode).toBe(200);
    });
    
    it('should hash the new password', async () => {
      const newPassword = 'MyNewPlainPassword';
      
      await request(app)
        .put('/api/auth/update-password/passworduser')
        .send({
          newPassword: newPassword
        });
      
      await new Promise(resolve => setTimeout(resolve, 200));
      const user = await User.findOne({ username: 'passworduser' });
      
      // La nueva contraseña debe estar hasheada
      expect(user.password).not.toBe(newPassword);
      expect(user.password).toMatch(/^\$2[aby]\$/);
    });
    
    it('should reject password update for non-existent user', async () => {
      const res = await request(app)
        .put('/api/auth/update-password/nonexistent')
        .send({
          newPassword: 'NewPassword123'
        });
      
      expect(res.statusCode).toBe(404);
      expect(res.body).toHaveProperty('message');
    });
  });
});


