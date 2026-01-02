# 🚀 Deploy Roomier en Railway - Guía Paso a Paso

## ✅ ESTADO: COMPLETADO - 2 de Enero 2026

### 🎉 Deployment Exitoso
- **Backend:** https://roomier-production.up.railway.app
- **Base de Datos:** MongoDB Atlas (cluster: roomier.8oraaik.mongodb.net)
- **Emails:** Resend API (100% funcional)
- **APK:** Generado con URLs de producción

## ⏱️ Tiempo estimado: 30 minutos

---

## PARTE 1: Preparar MongoDB Atlas (Base de Datos Gratis) ✅ COMPLETADO

### Paso 1: Crear cuenta en MongoDB Atlas ✅

1. ✅ Ve a https://www.mongodb.com/cloud/atlas/register
2. ✅ Crea una cuenta (gratis)
3. ✅ Click en **"Create a New Cluster"**
4. ✅ Selecciona:
   - **Provider:** AWS
   - **Region:** US East (N. Virginia)
   - **Tier:** M0 Sandbox (FREE) - 512MB storage
5. ✅ Click **"Create Cluster"** (tarda 3-5 minutos)

**Resultado:** Cluster creado → roomier.8oraaik. ✅

1. ✅ En el panel lateral, click **"Database Access"**
2. ✅ Click **"Add New Database User"**
   - Username: `baralle2014`
   - Password: Contraseña generada
   - Privileges: **Read and write to any database**
3. ✅ - Password: Genera una contraseña segura (guárdala)
   - Privileges: **Read and write to any database**
3. Click **"Add User"**

### Paso 3: Permitir conexiones ✅

1. ✅ Click **"Network Access"** en el panel lateral
2. ✅ Click **"Add IP Address"**
3. ✅ Click **"Allow Access from Anywhere"** (0.0.0.0/0)
4. ✅ Click **"Confirm"**

### Paso 4: Obtener Connection String

1. Click **"Database"** en el panel lateral
2. Click **"Connect"** en tu cluster
3. Click **"Connect your application"**
4. Copia el connection string, se ve así:
   ```
   mongodb+srv://roomier_admin:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. **IMPORTANTE:** Reemplaza `<password>` con tu contraseña real
6. Agrega el nombre de la base de datos antes del `?`:
   ```
   mongodb+srv://roomier_admin:TU_PASSWORD@cluster0.xxxxx.mongodb.net/flutter_auth?retryWrites=true&w=majority
   ```

---

## PARTE 2: Preparar el Código para Railway ✅ COMPLETADO

### Paso 1: Crear repositorio en GitHub ✅

```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier\backend"

# ✅ Inicializar git
git init

# ✅ Agregar archivos
git add .

# ✅ Primer commit
git commit -m "Initial commit - Roomier backend"

# ✅ Crear repositorio en GitHub
# Ve a https://github.com/new
# Crea un repositorio PÚBLICO llamado "Roomier"
# NO inicialices con README

# ✅ Conectar con GitHub
git remote add origin https://github.com/Franbaralle/Roomier.git
git branch -M main
git push -u origin main
```

**Resultado:** Repositorio creado → https://github.com/Franbaralle/Roomier

--- ✅ COMPLETADO

### Paso 1: Crear cuenta en Railway ✅

1. ✅ Ve a https://railway.app
2. ✅ Click **"Login"** 
3. ✅ Usa **"Login with GitHub"** (más fácil)
4. ✅ Autoriza Railway a acceder a tus repositorios

### Paso 2: Crear nuevo proyecto ✅

1. ✅ Click **"New Project"**
2. ✅ Selecciona **"Deploy from GitHub repo"**
3. ✅ Busca y selecciona **"Franbaralle/Roomier"**
4. ✅ Railway automáticamente:
   - Detecta que es Node.js
   - Instala dependencias
   - Hace deploy
5. ✅ Configurar root directory: `/backend` en Settingsjs
   - Instala dependencias ✅

1. ✅ En tu proyecto de Railway, click en tu servicio
2. ✅ Click en la pestaña **"Variables"**
3. ✅ Agrega estas variables (click **"New Variable"** para cada una):

```env
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://TU_USUARIO:TU_PASSWORD@roomier.8oraaik.mongodb.net/flutter_auth?retryWrites=true&w=majority
JWT_SECRET=TU_JWT_SECRET_DE_128_CARACTERES_HEX
JWT_EXPIRES_IN=24h
EMAIL_USER=tu_email@gmail.com
EMAIL_PASSWORD=tu_app_password_gmail
EMAIL_FROM=tu_email@gmail.com
RESEND_API_KEY=tu_api_key_de_resend
ALLOWED_ORIGINS=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=info
LOG_FILE=./logs/app.log
```

**⚠️ IMPORTANTE - SEGURIDAD:**
- **NUNCA** incluyas valores reales de credenciales en archivos de documentación
- Las credenciales deben estar SOLO en Railway Dashboard (Variables tab)
- Estos son valores de ejemplo que debes reemplazar con tus propios valores

**⚠️ NOTA:** EMAIL_HOST y EMAIL_PORT fueron eliminados (Railway bloquea SMTP). Usamos Resend API en su lugar.E_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=info
LOG_FILE=./logs/app.log
```

**⚠️ IMPORTANTE - Generar JWT_SECRET:**

En tu terminal de Windows:
```powershell ✅

1. ✅ En Railway, click en tu servicio
2. ✅ Ve a la pestaña **"Settings"**
3. ✅ Scroll hasta **"Networking"**
4. ✅ Click **"Generate Domain"**
5. ✅ Railway te dará una URL como: `roomier-production.up.railway.app`
6. ✅ **¡Guarda esta URL!** La necesitarás para Flutter

**Resultado:** URL generada → https://roomier-production.up.railway.app

### Paso 5: Verificar que funciona ✅

Abre en tu navegador:
```
https://roomier-production.up.railway.app/
```

✅ Deberías ver: **"Servidor en funcionamiento"**

Prueba el endpoint de salud:
```
https://roomier-production.up.railway.app/api
```

✅ **VERIFICADO:** Backend respondiend ✅ COMPLETADO

### Paso 1: Actualizar URL del API ✅

Busca en tu código Flutter donde está configurada la URL base. Probablemente en:
- ✅ `lib/auth_service.dart`
- ✅ `lib/chat_service.dart`
- ✅ `lib/admin_panel_page.dart`

**Buscar archivos:**
```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier"
```

En VS Code, busca (Ctrl+Shift+F): `http://localhost:3000`

✅ Reemplazadas todas las ocurrencias por:
```dart
// Antes:
final String baseUrl = 'http://localhost:3000/api';

// Después:
final String baseUrl = 'https://roomier-production.up.railway.app/api';
```

**Archivos actualizados:**
- ✅ lib/auth_service.dart (2 URLs)
- ✅ lib/chat_service.dart (1 URL)
- ✅ lib/admin_panel_page.dart (4 URLs)

### Paso 2: Regenerar APK ✅

```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier"
flutter build apk --release
```
 - COMPLETADO

### Checklist:
- [x] MongoDB Atlas cluster creado y accesible
- [x] Repositorio en GitHub (público: Franbaralle/Roomier)
- [x] Deploy en Railway exitoso
- [x] Variables de entorno configuradas (14 variables)
- [x] URL de Railway funcionando
- [x] Flutter actualizado con nueva URL
- [x] APK regenerado (21.2MB)
- [x] Sistema de emails funcionando (Resend API)
- [x] Trust proxy habilitado para Railway
- [x] Rate limiting configurado correctamente
- [x] Registro de usuarios funcionando ✅
- [x] Emails de verificación llegando ✅
- [x] Sistema de matching funcionando ✅

### Probar la app: ✅ PROBADO Y FUNCIONANDO
1. ✅ Instala el APK en tu celular
2. ✅ Intenta registrarte → **EXITOSO**
3. ✅ Verifica que los  - PROBLEMAS RESUELTOS

### ✅ Error: "Application failed to respond"
```
Solución aplicada: Verificado PORT=3000 en variables de entorno
```

### ✅ Error: "MongoServerError: Authentication failed"
```
Solución aplicada: 
1. Connection string corregido con contraseña correcta
2. Usuario con permisos de lectura/escritura configurado
3. 0.0.0.0/0 agregado en Network Access
```

### ✅ Error: "SMTP Connection Timeout"
```
Problema: Railway bloquea puertos SMTP (465 y 587)
Solución aplicada: Migrado de nodemailer a Resend API
- Instalado: resend@6.6.0
- Configurado: RESEND_API_KEY
- Resultado: Emails funcionando 100%
```

### ✅ Error: "Trust proxy validation error"
```
Problema: Railway usa X-Forwarded-For pero express-rate-limit se quejaba
Solución aplicada: 
1. Agregado app.set('trust proxy', true) en app.js
2. Agregado validate: { trustProxy: false } en rate limiters
```

### ✅ Error: "Cannot find module 'multer'"
```
Problema: node_modules de Windows subido a GitHub
Solución aplicada: 
1. Eliminado node_modules del repositorio
2. Railway instala dependencias automáticamente en Linux
```

### ✅ Error: "Invalid ELF header (bcrypt)"
```
Problema: bcrypt compilado para Windows, no Linux
Solución aplicada: Eliminado node_modules, Railway recompila bcrypt para Linux

---

## 🛠️ TROUBLESHOOTING

### Error: "Application failed to respond"
```
Solución: Verifica que PORT=3000 esté en las variables de entorno
```

### Error: "MongoServerError: Authentication failed"
```
Solución: 
1. Verifica que tu connection string tenga la contraseña correcta
2. Verifica que el usuario tenga permisos de lectura/escritura
3. Verifica que 0.0.0.0/0 esté en Network Access
```

### Error: "Cannot connect to Railway"
```
Solución:
1. Ve a Railway → Settings → Restart
2. Verifica los logs en Railway → Deployments → View Logs
```

### Ver Logs en Railway:
1. Click en tu ser exitoso:
1. ⏳ Monitorea logs las primeras 24 horas
2. ✅ Prueba todas las funcionalidades → **VERIFICADO**
3. 📱 Invita beta testers
4. 📊 Recolecta feedback
5. 🎨 Optimiza imágenes con Cloudinary (Gratis: 25GB)
6. 🔄 Configura backups automáticos de MongoDB
7. 📧 (Opcional) Configura dominio personalizado en Resend
8. 📈 Monitorea analytics en panel de administración

## 💡 TIPS IMPORTANTES

### 1. Railway Auto-Deploy
Cada vez que hagas `git push` a tu repo, Railway automáticamente hace re-deploy. ¡Muy conveniente!

### 2. Monitoreo
Railway te muestra:
- CPU usage
- Memory usage
- Request logs
- Error logs

### 3. Escalabilidad
Cuando tu app crezca, puedes:
- Agregar más recursos ($)
- Agregar Redis para caché
- Agregar workers para tareas pesadas

### 4. Backups de MongoDB
MongoDB Atlas hace backups automáticos en el tier gratuito.

---

## 📊 COSTOS

```
MongoDB Atlas (M0):   $0/mes
Railway (Free tier):  $0/mes (500 hrs + $5 crédito)
Total:                $0/mes 🎉
```

**Límites gratuitos:**
- Railway: ~$5/mes en recursos
- MongoDB: 512MB storage
- Suficiente para: Miles de usuarios en fase beta

---

## 🔄 PRÓXIMOS PASOS

Después del deploy:
1. ✅ Monitorea logs las primeras 24 horas
2. ✅ Prueba todas las funcionalidades
3. ✅ Invita beta testers
4. ✅ Recolecta feedback
5. ⏭️ Optimiza imágenes con Cloudinary (siguiente fase)

---

## 🆘 AYUDA

Si algo no funciona:
1. Revisa los logs en Railway
2. Verifica las variables de entorno
3. Asegúrate que MongoDB esté accesible
4. Verifica que el código esté pusheado a GitHub

---

¡Listo! Tu app Roomier está en producción y lista para beta testers. 🚀
