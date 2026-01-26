# 📋 Checklist de Migración: Railway → Render

## Fecha: 26 de Enero 2026

Esta guía te ayudará a migrar paso a paso sin tiempo de inactividad.

---

## ✅ FASE 1: Preparación (15 min)

### 1.1 Revisar configuración actual
- [ ] Acceder a Railway dashboard
- [ ] Exportar todas las variables de entorno actuales
- [ ] Anotar la URL actual del backend: `https://roomier-production.up.railway.app`
- [ ] Verificar qué servicios están corriendo (solo backend o también BD)

### 1.2 Copiar Variables de Entorno de Railway

Desde Railway, copia estas variables (están en Settings → Variables):

```bash
# Core
NODE_ENV=
PORT=

# Database
MONGO_URI=
# o
MONGODB_URI=

# Authentication
JWT_SECRET=

# Email Service
RESEND_API_KEY=

# Image Storage
CLOUDINARY_URL=
# o
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# Push Notifications
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# Opcional
ALLOWED_ORIGINS=
```

**💡 TIP:** Copia todas estas variables a un archivo temporal (NO lo subas a git).

---

## ✅ FASE 2: Configurar Render (20 min)

### 2.1 Crear cuenta y conectar GitHub
- [ ] Ir a https://render.com
- [ ] Sign in with GitHub
- [ ] Autorizar acceso al repositorio

### 2.2 Crear nuevo Web Service
- [ ] Click "New +" → "Web Service"
- [ ] Seleccionar repositorio: `Franbaralle/Roomier` (o tu repo)
- [ ] Click "Connect"

### 2.3 Configurar el servicio
- [ ] **Name:** `roomier-backend`
- [ ] **Region:** Oregon (Free)
- [ ] **Branch:** `main`
- [ ] **Root Directory:** `backend`
- [ ] **Environment:** Node
- [ ] **Build Command:** `npm install`
- [ ] **Start Command:** `node app.js`
- [ ] **Plan:** Free (por ahora)

### 2.4 Agregar Variables de Entorno
- [ ] Copiar todas las variables de Railway a Render
- [ ] **IMPORTANTE:** Verificar que `MONGO_URI` o `MONGODB_URI` esté correcto
- [ ] Verificar `FIREBASE_PRIVATE_KEY` con formato correcto (`\n` como texto literal)
- [ ] Click "Create Web Service"

### 2.5 Esperar el primer deploy
- [x] Monitorear logs durante el build (2-5 minutos)
- [x] Verificar que no haya errores
- [x] Anotar la nueva URL: `https://roomier-qeyu.onrender.com`

---

## ✅ FASE 3: Testing del nuevo servidor (15 min)

### 3.1 Verificar endpoints básicos

**Health Check:**
```bash
curl https://roomier-qeyu.onrender.com/health
```
Esperado: `{"status":"ok","timestamp":"..."}`

**Raíz:**
```bash
curl https://roomier-qeyu.onrender.com/
```
Esperado: `Servidor en funcionamiento` ✅ VERIFICADO

### 3.2 Probar autenticación

Usa Postman o curl para probar:

**Login:**
```bash
curl -X POST https://roomier-qeyu.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"testpass"}'
```

### 3.3 Verificar conexión a MongoDB
- [ ] El login debe funcionar (confirma conexión a BD)
- [ ] Revisar logs en Render para errores de MongoDB
- [ ] Si hay error: verificar IP whitelist en MongoDB Atlas (0.0.0.0/0)

### 3.4 Verificar Cloudinary
- [ ] Intentar subir una imagen de perfil
- [ ] Confirmar que se sube a Cloudinary correctamente

### 3.5 Verificar Firebase
- [ ] Enviar una notificación push de prueba
- [ ] Revisar logs para errores de Firebase

---

## ✅ FASE 4: Actualizar Flutter App (10 min)

### 4.1 Buscar archivos que usan la URL del API

```bash
# En la carpeta raíz de Roomier:
grep -r "roomier-production.up.railway.app" lib/
```

### 4.2 Actualizar URLs

Archivos comunes a revisar:
- [ ] `lib/auth_service.dart`
- [ ] `lib/chat_service.dart`
- [ ] `lib/api_service.dart`
- [ ] Cualquier otro servicio HTTP

**Cambio típico:**
```dart
// ANTES
static const String apiUrl = 'https://roomier-production.up.railway.app';

// DESPUÉS
static const String apiUrl = 'https://roomier-qeyu.onrender.com';
```

### 4.3 Testing local
```bash
flutter clean
flutter pub get
flutter run
```

- [ ] Probar login
- [ ] Probar registro
- [ ] Probar chat
- [ ] Probar subida de fotos
- [ ] Probar notificaciones

---

## ✅ FASE 5: Deploy Final (Opcional - 10 min)

### 5.1 Si necesitas generar APK nuevo

```bash
flutter build apk --release
```

El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### 5.2 Actualizar en tiendas (si aplica)
- [ ] Google Play Console (si ya está publicada)
- [ ] Distribuir a beta testers

---

## ✅ FASE 6: Transición y Limpieza

### 6.1 Periodo de prueba paralelo (Recomendado)

**Opción Conservadora:**
1. Mantén Railway activo por 1-2 semanas
2. Monitorea Render para asegurar estabilidad
3. Si todo va bien, procede a desactivar Railway

**Ventaja:** Puedes volver a Railway si hay problemas.

### 6.2 Desactivar Railway

Una vez confirmado que Render funciona perfectamente:

- [ ] Ir a Railway dashboard
- [ ] Ir a tu proyecto "Roomier"
- [ ] Settings → Danger Zone
- [ ] Click "Delete Project" o "Stop Service"
- [ ] Confirmar eliminación

### 6.3 Actualizar documentación

- [ ] Actualizar README.md con nueva URL
- [ ] Archivar RAILWAY_DEPLOY.md
- [ ] Usar RENDER_DEPLOY.md como referencia principal

---

## ⚠️ Plan B: Rollback a Railway

Si algo sale mal con Render:

1. **NO ELIMINES Railway todavía**
2. Revertir cambios en Flutter:
   ```dart
   // Volver a URL de Railway temporalmente
   static const String apiUrl = 'https://roomier-production.up.railway.app';
   ```
3. Rebuild app y redistribuir
4. Investigar el problema en Render
5. Reintentar cuando esté solucionado

---

## 🔧 Troubleshooting Común

### Problema: "MongoServerError: Authentication failed"
**Solución:**
- Verificar contraseña en MONGO_URI
- URL-encodear caracteres especiales
- Verificar IP whitelist en MongoDB Atlas

### Problema: "Cold start muy lento (60+ segundos)"
**Esto es normal en Free Tier de Render**
**Opciones:**
1. Aceptarlo temporalmente
2. Actualizar a plan Starter ($7/mes)
3. Usar un servicio de "keep-alive" externo

### Problema: "Firebase admin/app-check already exists"
**Solución:**
```javascript
// En utils/firebase.js, verificar:
if (!admin.apps.length) {
  admin.initializeApp({...});
}
```

### Problema: CORS errors desde Flutter
**Solución:**
- Verificar configuración CORS en app.js
- Agregar dominio de Render a ALLOWED_ORIGINS
- O usar '*' en desarrollo

---

## 📊 Costos Proyectados

### Railway (costo actual):
- Sin tier gratuito
- ~$5-20/mes dependiendo del uso

### Render:
- **Free Tier:** $0/mes (con cold starts)
- **Starter:** $7/mes (sin cold starts, recomendado para producción)
- **Standard:** $25/mes (para apps con más tráfico)

**Ahorro estimado:** $5-13/mes usando Render Free o Starter.

---

## ✅ Checklist Final de Verificación

Antes de considerar la migración completa:

- [ ] Backend en Render responde correctamente
- [ ] Todas las variables de entorno configuradas
- [ ] MongoDB conecta sin errores
- [ ] Cloudinary sube imágenes correctamente
- [ ] Firebase envía notificaciones
- [ ] Resend envía emails
- [ ] App Flutter actualizada y testeada
- [ ] Login/Registro funcionan
- [ ] Chat funciona
- [ ] Búsqueda de roommates funciona
- [ ] Notificaciones push funcionan
- [ ] No hay errores críticos en logs de Render
- [ ] Railway en standby por 1-2 semanas (seguridad)
- [ ] Documentación actualizada

---

## 📅 Timeline Sugerido

**Día 1 (Hoy):**
- Crear servicio en Render
- Configurar variables
- Testing básico

**Día 2-3:**
- Testing extensivo con app Flutter
- Ajustes y fixes

**Día 4-7:**
- Monitoreo de estabilidad
- Corrección de problemas menores

**Día 8-14:**
- Operación paralela Railway + Render
- Confirmación de estabilidad

**Día 15:**
- Desactivar Railway si todo está ok
- Migración completa

---

## 🎯 Próximos Pasos Inmediatos

1. [ ] Ejecutar FASE 1 completa (backup de variables)
2. [ ] Ejecutar FASE 2 completa (setup Render)
3. [ ] Ejecutar FASE 3 completa (testing)
4. [ ] Si todo OK → FASE 4 (actualizar Flutter)
5. [ ] Monitoreo por 1-2 semanas
6. [ ] Desactivar Railway

---

**¡Éxito en la migración! 🚀**

Creado: 26 de Enero 2026
