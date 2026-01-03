# Correcciones de Notificaciones Push y Mensajes Duplicados

## Problemas Resueltos

### 1. Mensajes Duplicados ✅
**Problema:** Los mensajes se enviaban tanto por Socket.IO como por HTTP, causando duplicación.

**Solución:**
- Eliminado el envío HTTP duplicado en `chat_page.dart`
- Ahora los mensajes solo se envían vía Socket.IO
- El backend ya guarda el mensaje en la BD cuando lo recibe por socket

### 2. Notificaciones No Aparecen en Background ✅
**Problema:** Las notificaciones push no se mostraban cuando la app estaba en segundo plano.

**Soluciones implementadas:**

#### Backend (Node.js):
- Agregado tracking de usuarios activos por chat específico
- Mejorada la lógica para enviar notificaciones:
  - Solo se envía si el usuario NO está viendo el chat actualmente
  - Se verifica estado activo en chat específico, no solo conexión general
- Eventos nuevos: `enter_chat` y `leave_chat` para mejor tracking

#### Frontend (Flutter):
- Configurado canal de notificaciones "chat_messages" en MainActivity.kt
- Mejorado formato de notificaciones en Firebase (backend)
- Agregados eventos de entrada/salida de chat para informar al backend

#### Android:
- Creado canal de notificaciones con importancia HIGH
- Configurado AndroidManifest con permisos correctos
- Agregado click_action para manejar toques en notificaciones

## Archivos Modificados

### Flutter (Frontend)
1. **lib/chat_page.dart**
   - Eliminado envío HTTP duplicado
   - Agregados lifecycle events para notificar entrada/salida del chat
   
2. **lib/socket_service.dart**
   - Agregado método `emit()` genérico para eventos personalizados
   
3. **lib/notification_service.dart**
   - Mejorados comentarios del handler de background
   
4. **android/app/src/main/kotlin/com/example/rommier/MainActivity.kt**
   - Agregada creación del canal de notificaciones para Android 8.0+

### Backend (Node.js)
1. **backend/app.js**
   - Agregado Map `activeChats` para tracking de usuarios activos por chat
   - Nuevos eventos: `enter_chat` y `leave_chat`
   - Mejorada lógica de envío de notificaciones
   - Limpieza automática al desconectar usuarios
   
2. **backend/utils/firebase.js**
   - Mejorada configuración de notificaciones Android
   - Agregado stringify de datos (requerido por FCM)
   - Agregadas opciones de sonido, vibración y click action
   - Mejor manejo de errores de tokens inválidos

## Cómo Probar

### Prueba 1: Mensajes No Duplicados
1. Abre la app en dos dispositivos con diferentes usuarios
2. Inicia un chat entre ellos
3. Envía varios mensajes
4. **Resultado esperado:** Cada mensaje debe aparecer solo una vez

### Prueba 2: Notificaciones en Background
1. Usuario A abre la app y va al home (NO al chat)
2. Usuario B envía un mensaje a Usuario A
3. **Resultado esperado:** Usuario A debe recibir notificación push con sonido

### Prueba 3: No Notificar si Chat Abierto
1. Usuario A abre el chat con Usuario B
2. Usuario B envía un mensaje
3. **Resultado esperado:** 
   - El mensaje aparece en tiempo real
   - NO debe sonar notificación (el usuario ya está viendo el chat)

### Prueba 4: Notificación con App Cerrada
1. Cierra completamente la app (swipe away)
2. Otro usuario envía mensaje
3. **Resultado esperado:** Debe aparecer notificación en bandeja del sistema

### Prueba 5: Click en Notificación
1. Recibe una notificación de chat
2. Toca la notificación
3. **Resultado esperado:** La app debe abrirse (idealmente al chat, pero mínimo a la app)

## Configuración Requerida

### Variables de Entorno Backend
Asegúrate de que el backend tenga configurado:
```
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account",...}
```

### Permisos Android
Ya configurados en AndroidManifest.xml:
- `android.permission.POST_NOTIFICATIONS`
- `android.permission.VIBRATE`
- `android.permission.RECEIVE_BOOT_COMPLETED`

## Troubleshooting

### Si las notificaciones siguen sin aparecer:

1. **Verificar permisos en el dispositivo:**
   - Configuración > Apps > Roomier > Notificaciones
   - Asegurar que estén habilitadas

2. **Verificar logs del backend:**
   ```
   "Notificación push enviada a [username]"
   "Usuario [username] está viendo el chat, no se envía notificación"
   ```

3. **Verificar token FCM:**
   - En logs de Flutter buscar: "Token FCM obtenido: ..."
   - Verificar que el token se envió al servidor correctamente

4. **Probar en dispositivo físico:**
   - Los emuladores a veces tienen problemas con notificaciones push
   - Probar siempre en dispositivo físico para validación final

5. **Verificar Firebase Console:**
   - Ir a Firebase Console > Cloud Messaging
   - Revisar estadísticas de mensajes enviados

### Si los mensajes siguen duplicados:

1. **Limpiar y reconstruir:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Verificar que no haya caché:**
   - Desinstalar app del dispositivo
   - Reinstalar desde cero

3. **Verificar logs de socket:**
   - Debe aparecer solo un "receive_message" por cada mensaje enviado

## Próximas Mejoras Recomendadas

1. **Navegación directa al chat:** Cuando se toca una notificación, abrir directamente el chat correspondiente
2. **Badge count:** Mostrar número de mensajes no leídos en el ícono de la app
3. **Sonidos personalizados:** Diferentes sonidos para diferentes tipos de notificaciones
4. **Notificaciones agrupadas:** Agrupar múltiples mensajes del mismo chat
5. **Quick reply:** Responder directamente desde la notificación sin abrir la app

## Notas Técnicas

- **Socket.IO es la fuente única de verdad** para mensajes en tiempo real
- **HTTP endpoints** se mantienen para operaciones de lectura y mantenimiento
- **activeChats Map** rastrea usuarios que tienen un chat abierto en pantalla
- **connectedUsers Map** rastrea usuarios conectados a Socket.IO (puede estar en home u otra parte)
- La diferencia entre ambos Maps es clave para el funcionamiento correcto
