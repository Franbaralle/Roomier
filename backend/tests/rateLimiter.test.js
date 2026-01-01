const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');
const User = require('../models/user');

// Mock de rate limiters para tests unitarios
jest.mock('../middleware/rateLimiter', () => ({
  loginLimiter: (req, res, next) => next(),
  registerLimiter: (req, res, next) => next(),
  apiLimiter: (req, res, next) => next(),
  passwordResetLimiter: (req, res, next) => next(),
  chatLimiter: (req, res, next) => next(),
  uploadLimiter: (req, res, next) => next()
}));

// Conectar a la base de datos de pruebas
beforeAll(async () => {
  const testDbUri = 'mongodb://localhost:27017/flutter_auth_test_ratelimit';
  
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  
  await mongoose.connect(testDbUri);
  
  await User.deleteMany({});
});

// Limpiar la base de datos después de cada test
afterEach(async () => {
  await User.deleteMany({});
  await new Promise(resolve => setTimeout(resolve, 100));
});

// Cerrar conexión después de todos los tests
afterAll(async () => {
  await User.deleteMany({});
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

describe('Rate Limiting Tests (Unit - Mocked)', () => {
  
  describe('Login Rate Limiting', () => {
    
    it('should allow 5 failed login attempts', async () => {
      // Intentar login 5 veces con credenciales incorrectas
      for (let i = 0; i < 5; i++) {
        const res = await request(app)
          .post('/api/auth/login')
          .send({
            username: 'nonexistent',
            password: 'wrongpass'
          });
        
        // Todos los primeros 5 intentos deben recibir 401 (no 429)
        expect(res.statusCode).toBe(401);
      }
    });
    
    it('should block after 5 failed login attempts', async () => {
      // Intentar login 6 veces
      for (let i = 0; i < 6; i++) {
        const res = await request(app)
          .post('/api/auth/login')
          .send({
            username: 'test',
            password: 'wrong'
          });
        
        if (i < 5) {
          // Los primeros 5 deben ser 401 (usuario/password incorrectos)
          expect(res.statusCode).toBe(401);
        } else {
          // El 6to debe ser bloqueado por rate limit (429)
          expect(res.statusCode).toBe(429);
          expect(res.body).toHaveProperty('error');
          expect(res.body.error).toMatch(/Demasiados intentos|Too many|rate limit/i);
        }
      }
    });
    
    it('should include rate limit headers', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'wrong'
        });
      
      // Verificar que incluye headers de rate limiting
      expect(res.headers).toHaveProperty('ratelimit-limit');
      expect(res.headers).toHaveProperty('ratelimit-remaining');
      
      // El límite debe ser 5
      expect(res.headers['ratelimit-limit']).toBe('5');
    });
    
    it('should count remaining attempts correctly', async () => {
      // Primer intento
      let res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'wrong'
        });
      
      expect(res.headers['ratelimit-remaining']).toBe('4');
      
      // Segundo intento
      res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'wrong'
        });
      
      expect(res.headers['ratelimit-remaining']).toBe('3');
      
      // Tercer intento
      res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'wrong'
        });
      
      expect(res.headers['ratelimit-remaining']).toBe('2');
    });
  });
  
  describe('Registration Rate Limiting', () => {
    
    it('should allow 3 registration attempts', async () => {
      // Intentar registrar 3 usuarios diferentes
      for (let i = 0; i < 3; i++) {
        const res = await request(app)
          .post('/api/auth/register')
          .send({
            username: `testuser${i}`,
            password: 'pass123',
            email: `test${i}@example.com`,
            birthdate: '2000-01-01',
            gender: 'masculino'
          });
        
        // Los primeros 3 deben tener éxito
        expect(res.statusCode).toBe(201);
      }
    });
    
    it('should block after 3 registration attempts', async () => {
      // Intentar registrar 4 usuarios
      for (let i = 0; i < 4; i++) {
        const res = await request(app)
          .post('/api/auth/register')
          .send({
            username: `reguser${i}`,
            password: 'pass123',
            email: `reg${i}@example.com`,
            birthdate: '2000-01-01',
            gender: 'femenino'
          });
        
        if (i < 3) {
          expect(res.statusCode).toBe(201);
        } else {
          // El 4to debe ser bloqueado
          expect(res.statusCode).toBe(429);
          expect(res.body.error).toMatch(/Demasiados registros|Too many|rate limit/i);
        }
      }
    });
    
    it('should include rate limit headers for registration', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'ratelimituser',
          password: 'pass123',
          email: 'rate@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      expect(res.headers).toHaveProperty('ratelimit-limit');
      expect(res.headers).toHaveProperty('ratelimit-remaining');
      
      // El límite de registro debe ser 3
      expect(res.headers['ratelimit-limit']).toBe('3');
    });
  });
  
  describe('Password Reset Rate Limiting', () => {
    
    // Crear usuario antes de los tests
    beforeEach(async () => {
      await request(app)
        .post('/api/auth/register')
        .send({
          username: 'resetuser',
          password: 'OldPass123',
          email: 'reset@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
    });
    
    it('should allow 3 password reset attempts', async () => {
      for (let i = 0; i < 3; i++) {
        const res = await request(app)
          .put('/api/auth/update-password/resetuser')
          .send({
            newPassword: `NewPass${i}23`
          });
        
        expect(res.statusCode).toBe(200);
      }
    });
    
    it('should block after 3 password reset attempts', async () => {
      for (let i = 0; i < 4; i++) {
        const res = await request(app)
          .put('/api/auth/update-password/resetuser')
          .send({
            newPassword: `NewPass${i}23`
          });
        
        if (i < 3) {
          expect(res.statusCode).toBe(200);
        } else {
          expect(res.statusCode).toBe(429);
          expect(res.body.error).toMatch(/Demasiados intentos|Too many|rate limit/i);
        }
      }
    });
  });
  
  describe('API Rate Limiting', () => {
    
    it('should have a general API rate limit', async () => {
      // El rate limit general debería ser más alto (100 requests/15min)
      // Solo verificamos que existe el header
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'test'
        });
      
      // Debe tener algún rate limit configurado
      expect(res.headers).toHaveProperty('ratelimit-limit');
      
      // El límite debe ser numérico
      const limit = parseInt(res.headers['ratelimit-limit']);
      expect(limit).toBeGreaterThan(0);
    });
  });
  
  describe('Rate Limit Reset', () => {
    
    it('should eventually reset after waiting period', async () => {
      // Este test es más conceptual ya que esperar 15 minutos no es práctico
      // Solo verificamos que el rate limit se aplica
      
      const res1 = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'wrong'
        });
      
      const remaining1 = parseInt(res1.headers['ratelimit-remaining']);
      
      const res2 = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'test',
          password: 'wrong'
        });
      
      const remaining2 = parseInt(res2.headers['ratelimit-remaining']);
      
      // El contador debe decrementar
      expect(remaining2).toBeLessThan(remaining1);
    }, 10000);
  });
  
  describe('Rate Limit per IP', () => {
    
    it('should track rate limits per IP address', async () => {
      // Los rate limiters están configurados por IP
      // Múltiples requests desde la misma IP deberían compartir el contador
      
      let lastRemaining = 5;
      
      for (let i = 0; i < 3; i++) {
        const res = await request(app)
          .post('/api/auth/login')
          .send({
            username: `user${i}`,
            password: 'wrong'
          });
        
        const currentRemaining = parseInt(res.headers['ratelimit-remaining']);
        
        // Cada request debe decrementar el contador
        expect(currentRemaining).toBeLessThan(lastRemaining);
        lastRemaining = currentRemaining;
      }
    });
  });
  
  describe('Successful Requests and Rate Limiting', () => {
    
    it('should count successful logins towards rate limit', async () => {
      // Crear un usuario real
      await request(app)
        .post('/api/auth/register')
        .send({
          username: 'realuser',
          password: 'RealPass123',
          email: 'real@example.com',
          birthdate: '2000-01-01',
          gender: 'masculino'
        });
      
      // Hacer login exitoso debería contar para el rate limit
      const res1 = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'realuser',
          password: 'RealPass123'
        });
      
      expect(res1.statusCode).toBe(200);
      const remaining1 = parseInt(res1.headers['ratelimit-remaining']);
      
      // Otro login exitoso
      const res2 = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'realuser',
          password: 'RealPass123'
        });
      
      expect(res2.statusCode).toBe(200);
      const remaining2 = parseInt(res2.headers['ratelimit-remaining']);
      
      // El contador debe seguir bajando incluso con logins exitosos
      expect(remaining2).toBeLessThan(remaining1);
    });
  });
});



