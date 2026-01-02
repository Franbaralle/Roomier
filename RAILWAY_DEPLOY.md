# 🚀 Deploy Roomier en Railway - Guía Paso a Paso

## ⏱️ Tiempo estimado: 30 minutos

---

## PARTE 1: Preparar MongoDB Atlas (Base de Datos Gratis)

### Paso 1: Crear cuenta en MongoDB Atlas

1. Ve a https://www.mongodb.com/cloud/atlas/register
2. Crea una cuenta (gratis)
3. Click en **"Create a New Cluster"**
4. Selecciona:
   - **Provider:** AWS
   - **Region:** Más cercana a ti (ej: N. Virginia, São Paulo)
   - **Tier:** M0 Sandbox (FREE)
5. Click **"Create Cluster"** (tarda 3-5 minutos)

### Paso 2: Configurar acceso a la base de datos

1. En el panel lateral, click **"Database Access"**
2. Click **"Add New Database User"**
   - Username: `roomier_admin`
   - Password: Genera una contraseña segura (guárdala)
   - Privileges: **Read and write to any database**
3. Click **"Add User"**

### Paso 3: Permitir conexiones

1. Click **"Network Access"** en el panel lateral
2. Click **"Add IP Address"**
3. Click **"Allow Access from Anywhere"** (0.0.0.0/0)
4. Click **"Confirm"**

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

## PARTE 2: Preparar el Código para Railway

### Paso 1: Crear repositorio en GitHub

```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier\backend"

# Inicializar git
git init

# Agregar archivos
git add .

# Primer commit
git commit -m "Initial commit - Roomier backend"

# Crear repositorio en GitHub
# Ve a https://github.com/new
# Crea un repositorio PRIVADO llamado "roomier-backend"
# NO inicialices con README

# Conectar con GitHub (reemplaza TU_USUARIO con tu usuario de GitHub)
git remote add origin https://github.com/TU_USUARIO/roomier-backend.git
git branch -M main
git push -u origin main
```

---

## PARTE 3: Deploy en Railway

### Paso 1: Crear cuenta en Railway

1. Ve a https://railway.app
2. Click **"Login"** 
3. Usa **"Login with GitHub"** (más fácil)
4. Autoriza Railway a acceder a tus repositorios

### Paso 2: Crear nuevo proyecto

1. Click **"New Project"**
2. Selecciona **"Deploy from GitHub repo"**
3. Busca y selecciona **"roomier-backend"**
4. Railway automáticamente:
   - Detecta que es Node.js
   - Instala dependencias
   - Intenta hacer deploy

### Paso 3: Configurar Variables de Entorno

1. En tu proyecto de Railway, click en tu servicio
2. Click en la pestaña **"Variables"**
3. Agrega estas variables (click **"New Variable"** para cada una):

```env
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://roomier_admin:TU_PASSWORD@cluster0.xxxxx.mongodb.net/flutter_auth?retryWrites=true&w=majority
JWT_SECRET=PEGAR_AQUI_LA_CLAVE_GENERADA
JWT_EXPIRES_IN=24h
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=tu_email@gmail.com
EMAIL_PASSWORD=tu_password_de_aplicacion_gmail
ALLOWED_ORIGINS=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=info
LOG_FILE=./logs/app.log
```

**⚠️ IMPORTANTE - Generar JWT_SECRET:**

En tu terminal de Windows:
```powershell
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```
Copia el resultado y úsalo como JWT_SECRET.

### Paso 4: Obtener URL de tu API

1. En Railway, click en tu servicio
2. Ve a la pestaña **"Settings"**
3. Scroll hasta **"Domains"**
4. Click **"Generate Domain"**
5. Railway te dará una URL como: `roomier-backend-production-xxxx.up.railway.app`
6. **¡Guarda esta URL!** La necesitarás para Flutter

### Paso 5: Verificar que funciona

Abre en tu navegador:
```
https://TU-URL-DE-RAILWAY.railway.app/
```

Deberías ver: **"Servidor en funcionamiento"**

Prueba el endpoint de salud:
```
https://TU-URL-DE-RAILWAY.railway.app/api
```

---

## PARTE 4: Actualizar la App Flutter

### Paso 1: Actualizar URL del API

Busca en tu código Flutter donde está configurada la URL base. Probablemente en:
- `lib/auth_service.dart`
- `lib/chat_service.dart`
- `lib/analytics_service.dart`

**Buscar archivos:**
```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier"
```

En VS Code, busca (Ctrl+Shift+F): `http://localhost:3000`

Reemplaza todas las ocurrencias por tu URL de Railway:
```dart
// Antes:
final String baseUrl = 'http://localhost:3000/api';

// Después:
final String baseUrl = 'https://TU-URL-DE-RAILWAY.railway.app/api';
```

### Paso 2: Regenerar APK

```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier"
flutter build apk --release
```

El APK estará en: `build\app\outputs\flutter-apk\app-release.apk`

---

## ✅ VERIFICACIÓN FINAL

### Checklist:
- [ ] MongoDB Atlas cluster creado y accesible
- [ ] Repositorio en GitHub (privado)
- [ ] Deploy en Railway exitoso
- [ ] Variables de entorno configuradas
- [ ] URL de Railway funcionando
- [ ] Flutter actualizado con nueva URL
- [ ] APK regenerado

### Probar la app:
1. Instala el APK en tu celular
2. Intenta registrarte
3. Verifica que los datos se guarden en MongoDB Atlas
4. Prueba login
5. Prueba matching y chat

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
1. Click en tu servicio
2. Click en **"Deployments"**
3. Click en el deployment más reciente
4. Click **"View Logs"**

---

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
