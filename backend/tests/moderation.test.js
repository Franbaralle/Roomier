const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');
const User = require('../models/user');
const Report = require('../models/report');
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/security');

// Mock de rate limiters para tests unitarios
jest.mock('../middleware/rateLimiter', () => ({
  loginLimiter: (req, res, next) => next(),
  registerLimiter: (req, res, next) => next(),
  apiLimiter: (req, res, next) => next(),
  passwordResetLimiter: (req, res, next) => next(),
  chatLimiter: (req, res, next) => next(),
  uploadLimiter: (req, res, next) => next()
}));

// Helper para crear usuario y obtener token
async function createUserAndGetToken(username, email) {
  const res = await request(app)
    .post('/api/auth/register')
    .send({
      username: username,
      password: 'Password123',
      email: email,
      birthdate: '2000-01-01',
      gender: 'masculino'
    });
  
  await new Promise(resolve => setTimeout(resolve, 100));
  return res.body.token;
}

// Conectar a la base de datos de pruebas
beforeAll(async () => {
  const testDbUri = 'mongodb://localhost:27017/flutter_auth_test_moderation';
  
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  
  await mongoose.connect(testDbUri);
  
  await User.deleteMany({});
  await Report.deleteMany({});
});

// Limpiar la base de datos después de cada test
afterEach(async () => {
  await User.deleteMany({});
  await Report.deleteMany({});
  await new Promise(resolve => setTimeout(resolve, 100));
});

// Cerrar conexión después de todos los tests
afterAll(async () => {
  await User.deleteMany({});
  await Report.deleteMany({});
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

describe('Moderation System Tests', () => {
  
  describe('POST /api/moderation/report', () => {
    
    let reporterToken;
    let reportedToken;
    
    beforeEach(async () => {
      // Crear dos usuarios: uno que reporta y uno reportado
      reporterToken = await createUserAndGetToken('reporter', 'reporter@test.com');
      reportedToken = await createUserAndGetToken('baduser', 'bad@test.com');
    });
    
    it('should create report with valid token and data', async () => {
      const res = await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'baduser',
          reason: 'harassment',
          description: 'Usuario con comportamiento inapropiado'
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/Reporte enviado exitosamente/i);
      expect(res.body).toHaveProperty('reportId');
      
      // Verificar que el reporte existe en la BD
      const report = await Report.findById(res.body.reportId);
      expect(report).toBeTruthy();
      expect(report.reportedUser).toBe('baduser');
      expect(report.reportedBy).toBe('reporter');
      expect(report.reason).toBe('harassment');
      expect(report.status).toBe('pending');
    });
    
    it('should reject report without authentication token', async () => {
      const res = await request(app)
        .post('/api/moderation/report')
        .send({
          reportedUser: 'baduser',
          reason: 'spam',
          description: 'Usuario spammer'
        });
      
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
      expect(res.body.error).toMatch(/Acceso denegado|token/i);
    });
    
    it('should reject report with invalid token', async () => {
      const res = await request(app)
        .post('/api/moderation/report')
        .set('Authorization', 'Bearer invalid_token_12345')
        .send({
          reportedUser: 'baduser',
          reason: 'spam'
        });
      
      expect(res.statusCode).toBe(401);
    });
    
    it('should prevent self-reporting', async () => {
      const res = await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'reporter', // Intentando reportarse a sí mismo
          reason: 'spam',
          description: 'Test'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
      expect(res.body.error).toMatch(/ti mismo|Acción no permitida/i);
    });
    
    it('should prevent duplicate reports from same user', async () => {
      // Primer reporte
      await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'baduser',
          reason: 'harassment',
          description: 'Primera vez'
        });
      
      // Segundo reporte del mismo usuario
      const res = await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'baduser',
          reason: 'spam',
          description: 'Segunda vez'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/Ya has reportado|anteriormente|Reporte duplicado/i);
    });
    
    it('should reject report for non-existent user', async () => {
      const res = await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'nonexistentuser',
          reason: 'spam',
          description: 'Usuario que no existe'
        });
      
      expect(res.statusCode).toBe(404);
      expect(res.body.error).toMatch(/no existe|Usuario no encontrado/i);
    });
    
    it('should accept all valid report reasons', async () => {
      const validReasons = [
        'inappropriate_behavior',
        'fake_profile',
        'harassment',
        'spam',
        'offensive_content',
        'scam',
        'underage',
        'impersonation',
        'other'
      ];
      
      for (let i = 0; i < validReasons.length; i++) {
        const token = await createUserAndGetToken(`reporter${i}`, `reporter${i}@test.com`);
        
        const res = await request(app)
          .post('/api/moderation/report')
          .set('Authorization', `Bearer ${token}`)
          .send({
            reportedUser: 'baduser',
            reason: validReasons[i],
            description: `Test for ${validReasons[i]}`
          });
        
        expect(res.statusCode).toBe(201);
      }
    });
    
    it('should reject invalid report reason', async () => {
      const res = await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'baduser',
          reason: 'invalid_reason_not_in_enum',
          description: 'Test'
        });
      
      expect([400, 500]).toContain(res.statusCode); // Puede ser 400 o 500
    });
  });
  
  describe('POST /api/moderation/block', () => {
    
    let userToken;
    let targetToken;
    
    beforeEach(async () => {
      userToken = await createUserAndGetToken('blocker', 'blocker@test.com');
      targetToken = await createUserAndGetToken('toblockeduser', 'blocked@test.com');
    });
    
    it('should block user successfully', async () => {
      const res = await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'toblockeduser'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toMatch(/bloqueado exitosamente/i);
      expect(res.body).toHaveProperty('blockedUsers');
      expect(res.body.blockedUsers).toContain('toblockeduser');
      
      // Verificar en la BD
      const user = await User.findOne({ username: 'blocker' });
      expect(user.blockedUsers).toContain('toblockeduser');
    });
    
    it('should require authentication to block', async () => {
      const res = await request(app)
        .post('/api/moderation/block')
        .send({
          blockedUser: 'toblockeduser'
        });
      
      expect(res.statusCode).toBe(401);
    });
    
    it('should prevent blocking yourself', async () => {
      const res = await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'blocker' // Intentando bloquearse a sí mismo
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body.error).toMatch(/ti mismo|Acción no permitida/i);
    });
    
    it('should prevent blocking non-existent user', async () => {
      const res = await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'nonexistentuser'
        });
      
      expect(res.statusCode).toBe(404);
    });
    
    it('should handle blocking already blocked user', async () => {
      // Bloquear primera vez
      await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'toblockeduser'
        });
      
      // Bloquear segunda vez
      const res = await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'toblockeduser'
        });
      
      // El backend puede ser idempotente (200) o rechazar (400)
      expect([200, 400]).toContain(res.statusCode);
      if (res.statusCode === 400) {
        expect(res.body.error).toMatch(/Ya has bloqueado|ya bloqueado/i);
      }
    });
    
    it('should remove mutual matches when blocking', async () => {
      // Crear usuarios con match mutuo
      const user1 = await User.findOne({ username: 'blocker' });
      const user2 = await User.findOne({ username: 'toblockeduser' });
      
      // Simular match mutuo
      user1.matches = ['toblockeduser'];
      user2.matches = ['blocker'];
      await user1.save();
      await user2.save();
      
      // Bloquear
      await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'toblockeduser'
        });
      
      // Verificar que el match fue eliminado
      const updatedUser1 = await User.findOne({ username: 'blocker' });
      const updatedUser2 = await User.findOne({ username: 'toblockeduser' });
      
      if (updatedUser1.matches) {
        expect(updatedUser1.matches).not.toContain('toblockeduser');
      }
      if (updatedUser2.matches) {
        expect(updatedUser2.matches).not.toContain('blocker');
      }
    });
  });
  
  describe('POST /api/moderation/unblock', () => {
    
    let userToken;
    
    beforeEach(async () => {
      userToken = await createUserAndGetToken('unblocker', 'unblocker@test.com');
      await createUserAndGetToken('unblockeduser', 'unblocked@test.com');
      
      // Bloquear primero
      await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          blockedUser: 'unblockeduser'
        });
    });
    
    it('should unblock user successfully', async () => {
      const res = await request(app)
        .post('/api/moderation/unblock')
        .set('Authorization', `Bearer ${userToken}`)
        .send({
          unblockedUser: 'unblockeduser'
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body.message).toMatch(/desbloqueado exitosamente/i);
      expect(res.body.blockedUsers).not.toContain('unblockeduser');
      
      // Verificar en BD
      const user = await User.findOne({ username: 'unblocker' });
      expect(user.blockedUsers).not.toContain('unblockeduser');
    });
    
    it('should require authentication to unblock', async () => {
      const res = await request(app)
        .post('/api/moderation/unblock')
        .send({
          unblockedUser: 'unblockeduser'
        });
      
      expect(res.statusCode).toBe(401);
    });
    
    it('should handle unblocking user that was not blocked', async () => {
      const token = await createUserAndGetToken('newuser', 'new@test.com');
      
      const res = await request(app)
        .post('/api/moderation/unblock')
        .set('Authorization', `Bearer ${token}`)
        .send({
          unblockedUser: 'unblockeduser'
        });
      
      // El backend puede ser idempotente (200) o rechazar (400)
      expect([200, 400]).toContain(res.statusCode);
      if (res.statusCode === 400) {
        expect(res.body.error).toMatch(/no está bloqueado|not blocked/i);
      }
    });
  });
  
  describe('GET /api/moderation/blocked', () => {
    
    let userToken;
    
    beforeEach(async () => {
      userToken = await createUserAndGetToken('lister', 'lister@test.com');
      await createUserAndGetToken('blocked1', 'blocked1@test.com');
      await createUserAndGetToken('blocked2', 'blocked2@test.com');
      await createUserAndGetToken('blocked3', 'blocked3@test.com');
      
      // Bloquear varios usuarios
      await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ blockedUser: 'blocked1' });
      
      await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ blockedUser: 'blocked2' });
      
      await request(app)
        .post('/api/moderation/block')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ blockedUser: 'blocked3' });
    });
    
    it('should return list of blocked users', async () => {
      const res = await request(app)
        .get('/api/moderation/blocked')
        .set('Authorization', `Bearer ${userToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('blockedUsers');
      expect(Array.isArray(res.body.blockedUsers)).toBe(true);
      expect(res.body.blockedUsers).toHaveLength(3);
      expect(res.body.blockedUsers).toContain('blocked1');
      expect(res.body.blockedUsers).toContain('blocked2');
      expect(res.body.blockedUsers).toContain('blocked3');
    });
    
    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/moderation/blocked');
      
      expect(res.statusCode).toBe(401);
    });
    
    it('should return empty array if no blocked users', async () => {
      const newToken = await createUserAndGetToken('newlister', 'newlister@test.com');
      
      const res = await request(app)
        .get('/api/moderation/blocked')
        .set('Authorization', `Bearer ${newToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body.blockedUsers).toEqual([]);
    });
  });
  
  describe('GET /api/moderation/my-reports', () => {
    
    let reporterToken;
    
    beforeEach(async () => {
      reporterToken = await createUserAndGetToken('myreporter', 'myreporter@test.com');
      await createUserAndGetToken('bad1', 'bad1@test.com');
      await createUserAndGetToken('bad2', 'bad2@test.com');
      
      // Crear varios reportes
      await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'bad1',
          reason: 'harassment',
          description: 'First report'
        });
      
      await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${reporterToken}`)
        .send({
          reportedUser: 'bad2',
          reason: 'spam',
          description: 'Second report'
        });
    });
    
    it('should return list of user reports', async () => {
      const res = await request(app)
        .get('/api/moderation/my-reports')
        .set('Authorization', `Bearer ${reporterToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('reports');
      expect(Array.isArray(res.body.reports)).toBe(true);
      expect(res.body.reports).toHaveLength(2);
      
      // Verificar estructura de los reportes
      res.body.reports.forEach(report => {
        expect(report).toHaveProperty('reportedUser');
        expect(report).toHaveProperty('reason');
        expect(report).toHaveProperty('description');
        expect(report).toHaveProperty('status');
        expect(report).toHaveProperty('createdAt');
      });
    });
    
    it('should require authentication', async () => {
      const res = await request(app)
        .get('/api/moderation/my-reports');
      
      expect(res.statusCode).toBe(401);
    });
    
    it('should return empty array if no reports', async () => {
      const newToken = await createUserAndGetToken('newreporter', 'newreporter@test.com');
      
      const res = await request(app)
        .get('/api/moderation/my-reports')
        .set('Authorization', `Bearer ${newToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body.reports).toEqual([]);
    });
    
    it('should only return current user reports', async () => {
      // Crear otro usuario que también hace reportes
      const otherToken = await createUserAndGetToken('otherreporter', 'other@test.com');
      await createUserAndGetToken('bad3', 'bad3@test.com');
      
      await request(app)
        .post('/api/moderation/report')
        .set('Authorization', `Bearer ${otherToken}`)
        .send({
          reportedUser: 'bad3',
          reason: 'scam',
          description: 'Other user report'
        });
      
      // Obtener reportes del primer usuario
      const res = await request(app)
        .get('/api/moderation/my-reports')
        .set('Authorization', `Bearer ${reporterToken}`);
      
      // Solo debe ver sus propios reportes (2), no los del otro usuario
      expect(res.body.reports).toHaveLength(2);
      expect(res.body.reports.every(r => r.reportedBy === 'myreporter')).toBe(true);
    });
  });
});



