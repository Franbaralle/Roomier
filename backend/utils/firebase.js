const admin = require('firebase-admin');
const logger = require('./logger');

let firebaseInitialized = false;

/**
 * Inicializar Firebase Admin SDK
 * Requiere que FIREBASE_SERVICE_ACCOUNT_KEY esté configurado en las variables de entorno
 */
function initializeFirebase() {
  if (firebaseInitialized) {
    return;
  }

  try {
    const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    
    if (!serviceAccountKey) {
      logger.warn('FIREBASE_SERVICE_ACCOUNT_KEY no configurado. Las notificaciones push no estarán disponibles.');
      return;
    }

    // Parse el JSON del service account key
    const serviceAccount = JSON.parse(serviceAccountKey);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    firebaseInitialized = true;
    logger.info('✅ Firebase Admin SDK inicializado correctamente');
  } catch (error) {
    logger.error(`Error inicializando Firebase Admin SDK: ${error.message}`);
  }
}

/**
 * Enviar notificación push a un usuario específico
 * @param {string} fcmToken - Token FCM del dispositivo del usuario
 * @param {object} notification - Datos de la notificación
 * @param {string} notification.title - Título de la notificación
 * @param {string} notification.body - Cuerpo de la notificación
 * @param {object} data - Datos adicionales (opcional)
 */
async function sendPushNotification(fcmToken, notification, data = {}) {
  if (!firebaseInitialized) {
    logger.warn('Firebase no inicializado. No se puede enviar notificación.');
    return null;
  }

  try {
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data,
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'chat_messages',
        },
      },
    };

    const response = await admin.messaging().send(message);
    logger.info(`Notificación push enviada exitosamente: ${response}`);
    return response;
  } catch (error) {
    logger.error(`Error enviando notificación push: ${error.message}`);
    return null;
  }
}

/**
 * Enviar notificación push a múltiples usuarios
 * @param {Array<string>} fcmTokens - Array de tokens FCM
 * @param {object} notification - Datos de la notificación
 * @param {object} data - Datos adicionales (opcional)
 */
async function sendMultiplePushNotifications(fcmTokens, notification, data = {}) {
  if (!firebaseInitialized) {
    logger.warn('Firebase no inicializado. No se puede enviar notificaciones.');
    return null;
  }

  try {
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data,
      tokens: fcmTokens,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'chat_messages',
        },
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    logger.info(`Notificaciones enviadas: ${response.successCount} exitosas, ${response.failureCount} fallidas`);
    return response;
  } catch (error) {
    logger.error(`Error enviando notificaciones múltiples: ${error.message}`);
    return null;
  }
}

/**
 * Verificar si un token FCM es válido
 * @param {string} fcmToken - Token FCM a verificar
 */
async function validateFCMToken(fcmToken) {
  if (!firebaseInitialized || !fcmToken) {
    return false;
  }

  try {
    // Intentar enviar un mensaje de prueba (dry run)
    const message = {
      token: fcmToken,
      notification: {
        title: 'Test',
        body: 'Test',
      },
    };
    
    await admin.messaging().send(message, true); // dry run
    return true;
  } catch (error) {
    logger.warn(`Token FCM inválido o expirado: ${error.code}`);
    return false;
  }
}

module.exports = {
  initializeFirebase,
  sendPushNotification,
  sendMultiplePushNotifications,
  validateFCMToken,
};
