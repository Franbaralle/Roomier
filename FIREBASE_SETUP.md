# Configuración de Firebase Cloud Messaging

## ✅ Completado

### Frontend (Flutter)
- ✅ Firebase Core y Firebase Messaging instalados
- ✅ `google-services.json` configurado en `android/app/`
- ✅ `firebase_options.dart` con credenciales de Firebase
- ✅ AndroidManifest actualizado con permisos de notificaciones
- ✅ NotificationService creado para manejar notificaciones
- ✅ Inicialización en main.dart

### Backend (Node.js)
- ✅ firebase-admin instalado
- ✅ Servicio de Firebase (`utils/firebase.js`) creado
- ✅ Ruta `/api/notifications/token` para guardar tokens FCM
- ✅ Socket.IO integrado con envío de notificaciones push
- ✅ Modelo User actualizado con campo `fcmToken`

## 🔧 Configuración Pendiente

### Railway (Backend)
Necesitas configurar la variable de entorno en Railway:

1. Ve a https://railway.app/
2. Selecciona tu proyecto backend
3. Ve a Variables → New Variable
4. **Nombre**: `FIREBASE_SERVICE_ACCOUNT_KEY`
5. **Valor**: El JSON completo del Service Account Key de Firebase
6. Guarda (Railway redesplegará automáticamente)

## 📱 Cómo Funciona

### Flujo de Notificaciones:

1. **Usuario abre la app**:
   - Firebase genera un token FCM único para el dispositivo
   - Se envía al backend: `POST /api/notifications/token`
   - Se guarda en el usuario: `user.fcmToken`

2. **Usuario recibe mensaje (tiempo real)**:
   - Si está en el chat: Recibe via Socket.IO (instantáneo)
   - Si NO está en el chat: Recibe notificación push via FCM

3. **Usuario toca la notificación**:
   - La app se abre directamente en el chat correspondiente
   - Los mensajes se marcan como leídos automáticamente

### Eventos de Socket.IO:
- `send_message`: Envía mensaje y notificación push si el usuario no está conectado
- `receive_message`: Recibe mensaje en tiempo real
- `typing` / `stop_typing`: Indicadores de escritura
- `mark_as_read`: Marca mensajes como leídos

## 🔐 Seguridad

- El Service Account Key se almacena como variable de entorno (no en código)
- Los tokens FCM se validan en cada uso
- Las notificaciones solo se envían a usuarios autenticados
- Los datos sensibles no se incluyen en las notificaciones

## 📊 Datos de Firebase

**Project ID**: roomier-c64f0
**Messaging Sender ID**: 915280538892
**Package Name**: com.example.rommier

## 🧪 Testing

Para probar las notificaciones:

1. Ejecuta la app en 2 dispositivos/emuladores
2. Inicia sesión con usuarios diferentes
3. Crea un match entre ellos
4. Envía un mensaje desde un dispositivo
5. Verifica que el otro recibe:
   - Notificación push (si la app está cerrada/background)
   - Mensaje en tiempo real (si está en el chat)

## 📝 Notas

- Las notificaciones push requieren Google Play Services (disponible en emuladores con Play Store)
- En producción, considera usar canales de notificación personalizados
- Los tokens FCM pueden expirar, el sistema los renueva automáticamente
- El canal "chat_messages" está configurado para prioridad alta

## 🐛 Troubleshooting

### "Notificaciones no llegan":
- Verifica que FIREBASE_SERVICE_ACCOUNT_KEY esté configurado en Railway
- Revisa los logs del backend: `railway logs`
- Verifica que el usuario tenga fcmToken en la base de datos

### "Error inicializando Firebase":
- Verifica que google-services.json esté en android/app/
- Verifica que el package name coincida: com.example.rommier
- Limpia y reconstruye: `flutter clean && flutter run`

### "Socket.IO no conecta":
- Verifica la URL del servidor en socket_service.dart
- Revisa que Railway esté ejecutándose
- Verifica los logs de conexión en la consola
