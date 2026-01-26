# 🚀 Deploy Roomier en Render - Guía Completa

## ✅ Ventajas de Render sobre Railway

- **Tier Gratuito:** 750 horas/mes gratis (suficiente para 1 instancia 24/7)
- **Pricing Predecible:** $7/mes para plan básico sin cold starts
- **Base de Datos:** PostgreSQL gratis incluida (hasta 90 días retención)
- **Mejor Uptime:** Mayor estabilidad en 2025-2026
- **Deploy Automático:** Desde GitHub sin configuración compleja

## ⚠️ Limitación del Tier Gratuito

Los servicios gratuitos se "duermen" después de 15 minutos de inactividad.
- Primera petición después de dormir: ~30-60 segundos (cold start)
- **Solución:** Actualizar a plan de pago ($7/mes) para servicio 24/7 sin interrupciones

---

## ⏱️ Tiempo estimado: 45 minutos

---

## PARTE 1: Preparar MongoDB Atlas (si no lo tienes ya)

### Si ya tienes MongoDB Atlas configurado:
✅ Puedes usar la misma base de datos que usabas con Railway.
✅ Solo necesitas asegurarte de que la IP de Render tenga acceso (0.0.0.0/0).

### Si no tienes MongoDB Atlas:

1. Ve a https://www.mongodb.com/cloud/atlas/register
2. Crea una cuenta gratuita
3. Click en **"Create a New Cluster"**
4. Selecciona:
   - **Provider:** AWS
   - **Region:** US East (N. Virginia) - Cerca de Render
   - **Tier:** M0 Sandbox (FREE) - 512MB storage
5. Click **"Create Cluster"** (tarda 3-5 minutos)

### Crear usuario de base de datos:

1. En el panel lateral, click **"Database Access"**
2. Click **"Add New Database User"**
   - Username: `roomier_admin` (o el que prefieras)
   - Password: Genera una contraseña segura (guárdala)
   - Privileges: **Read and write to any database**
3. Click **"Add User"**

### Permitir conexiones:

1. Click **"Network Access"** en el panel lateral
2. Click **"Add IP Address"**
3. Click **"Allow Access from Anywhere"** (0.0.0.0/0)
4. Click **"Confirm"**

### Obtener Connection String:

1. Click **"Database"** en el panel lateral
2. Click **"Connect"** en tu cluster
3. Click **"Connect your application"**
4. Copia el connection string:
   ```
   mongodb+srv://roomier_admin:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
5. **IMPORTANTE:** Reemplaza `<password>` con tu contraseña real
6. Agrega el nombre de la base de datos antes del `?`:
   ```
   mongodb+srv://roomier_admin:TU_PASSWORD@cluster0.xxxxx.mongodb.net/flutter_auth?retryWrites=true&w=majority
   ```

---

## PARTE 2: Preparar el Código para Render

### Paso 1: Asegurar que el código esté en GitHub

```bash
cd "c:\Users\usuario\OneDrive\Desktop\Roomier\backend"

# Si ya tienes git configurado:
git add .
git commit -m "Preparando para deploy en Render"
git push origin main
```

### Paso 2: Verificar archivos necesarios

✅ **render.yaml** - Ya creado en la raíz de backend/
✅ **package.json** - Debe tener `"start": "node app.js"`
✅ **app.js** - Debe tener endpoint `/health`

---

## PARTE 3: Deploy en Render

### Paso 1: Crear cuenta en Render

1. Ve a https://render.com
2. Click **"Get Started"**
3. Usa **"Sign in with GitHub"** (más fácil y recomendado)
4. Autoriza Render a acceder a tus repositorios

### Paso 2: Crear nuevo Web Service

1. En el dashboard de Render, click **"New +"**
2. Selecciona **"Web Service"**
3. Conecta tu repositorio de GitHub:
   - Si usas el mismo repo que Railway: **"Franbaralle/Roomier"**
   - Si es un repo nuevo, selecciónalo de la lista
4. Click **"Connect"**

### Paso 3: Configurar el servicio

#### Información básica:
- **Name:** `roomier-backend` (o el nombre que prefieras)
- **Region:** Oregon (Free tier disponible)
- **Branch:** `main`
- **Root Directory:** `backend` (si tu backend está en una subcarpeta)
- **Environment:** Node
- **Build Command:** `npm install`
- **Start Command:** `node app.js`

#### Plan:
- Selecciona **"Free"** para empezar
- Puedes actualizar a **"Starter ($7/mes)"** después para evitar cold starts

### Paso 4: Configurar Variables de Entorno

En la sección **"Environment Variables"**, agrega las siguientes:

#### Variables obligatorias:

```
NODE_ENV=production
PORT=10000
```

#### MongoDB:
```
MONGO_URI=mongodb+srv://tu_usuario:tu_password@cluster0.xxxxx.mongodb.net/flutter_auth?retryWrites=true&w=majority
```
*(O la variable que uses: MONGODB_URI)*

#### JWT:
```
JWT_SECRET=tu_secreto_jwt_super_seguro_aqui
```

#### Resend (Email):
```
RESEND_API_KEY=tu_api_key_de_resend
```

#### Cloudinary (Imágenes):
Opción 1 - Variable única:
```
CLOUDINARY_URL=cloudinary://api_key:api_secret@cloud_name
```

Opción 2 - Variables separadas:
```
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret
```

#### Firebase (Notificaciones):
```
FIREBASE_PROJECT_ID=tu_project_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nTU_CLAVE_PRIVADA\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tu-proyecto.iam.gserviceaccount.com
```

**IMPORTANTE para FIREBASE_PRIVATE_KEY:**
- Debe estar entre comillas dobles
- Los saltos de línea deben ser `\n`
- Ejemplo: `"-----BEGIN PRIVATE KEY-----\nMIIEvQI...clave...==\n-----END PRIVATE KEY-----\n"`

### Paso 5: Deploy

1. Click **"Create Web Service"**
2. Render comenzará a construir y deployar tu aplicación
3. El proceso tarda aproximadamente 3-5 minutos

### Paso 6: Verificar el Deploy

Una vez completado el deploy:

1. Render te dará una URL como: `https://roomier-backend.onrender.com`
2. Verifica que funciona:
   ```
   https://roomier-backend.onrender.com/health
   ```
   Deberías ver: `{"status":"ok","timestamp":"2026-01-26T..."}`

3. Prueba el endpoint de login o registro para confirmar que MongoDB funciona

---

## PARTE 4: Actualizar tu App Flutter

### Paso 1: Actualizar la URL del backend

Busca en tu código Flutter donde defines la URL del API:

```dart
// Antes (Railway):
// static const String apiUrl = 'https://roomier-production.up.railway.app';

// Después (Render):
static const String apiUrl = 'https://roomier-backend.onrender.com';
```

### Paso 2: Archivos típicos donde actualizar:

- `lib/auth_service.dart`
- `lib/chat_service.dart`
- `lib/api_service.dart` (o similar)
- Cualquier servicio que haga peticiones HTTP

### Paso 3: Rebuild y prueba

```bash
flutter clean
flutter pub get
flutter run
```

---

## PARTE 5: Configuraciones Opcionales (Recomendadas)

### Health Check Path

Render verificará automáticamente `/health` cada 30 segundos para asegurarse de que tu servicio esté activo.

### Auto-Deploy

Por defecto, Render hace auto-deploy cuando haces push a GitHub:
- Commits a `main` → Deploy automático
- Puedes desactivar esto en Settings si prefieres deploys manuales

### Custom Domain (Opcional)

Si tienes un dominio:
1. Ve a Settings → Custom Domain
2. Agrega tu dominio (ej: `api.roomier.com`)
3. Configura los DNS según las instrucciones de Render
4. SSL/HTTPS es automático y gratis

---

## PARTE 6: Monitoreo y Logs

### Ver Logs en tiempo real:

1. En tu servicio en Render, click en la pestaña **"Logs"**
2. Verás todos los logs de tu aplicación en tiempo real
3. Útil para debugging

### Métricas:

1. Pestaña **"Metrics"** muestra:
   - Uso de CPU
   - Uso de memoria
   - Requests por minuto
   - Tiempos de respuesta

---

## 🔥 Solución de Problemas Comunes

### 1. Service no inicia (Build Failed)

**Problema:** Error durante `npm install`
**Solución:**
- Verifica que `package.json` esté en la carpeta correcta
- Asegúrate de que "Root Directory" esté configurado correctamente
- Revisa los logs de build para el error específico

### 2. MongoDB Connection Error

**Problema:** `MongoServerError: Authentication failed`
**Solución:**
- Verifica que la contraseña en MONGO_URI sea correcta
- No debe tener caracteres especiales sin encodear
- Ejemplo: `p@ssw0rd` debe ser `p%40ssw0rd`
- Usa: https://www.urlencoder.org/

### 3. Cold Starts (Free Tier)

**Problema:** Primera petición muy lenta después de inactividad
**Esto es normal en el free tier**

**Soluciones:**
- **Temporal:** Hacer un ping cada 10 minutos con un cron job externo
- **Definitiva:** Actualizar a plan Starter ($7/mes)

### 4. Firebase Private Key Error

**Problema:** `Error: Invalid PEM formatted message`
**Solución:**
```bash
# La clave debe tener \n literal, no saltos de línea reales
"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADA...tu_clave...==\n-----END PRIVATE KEY-----\n"
```

### 5. CORS Error desde Flutter

**Problema:** `Access-Control-Allow-Origin error`
**Solución:**
- Verifica que tu app.js tenga configuración CORS correcta
- En producción, especifica el origen exacto en vez de '*'

---

## 📊 Comparación: Railway vs Render

| Característica | Railway | Render |
|---------------|---------|--------|
| **Tier Gratuito** | Eliminado | 750 hrs/mes |
| **Precio Básico** | $5/mes + uso | $7/mes fijo |
| **Cold Starts** | No | Sí (free tier) |
| **PostgreSQL Gratis** | No | Sí |
| **Auto-Deploy** | Sí | Sí |
| **Custom Domain** | Sí | Sí (gratis SSL) |
| **Soporte** | Email | Email + Docs |

---

## ✅ Checklist Final

Antes de considerar el deploy completo:

- [ ] Backend responde en la URL de Render
- [ ] Endpoint `/health` funciona
- [ ] Login/Register funcionan correctamente
- [ ] Subida de imágenes funciona (Cloudinary)
- [ ] Notificaciones push funcionan (Firebase)
- [ ] Emails se envían correctamente (Resend)
- [ ] App Flutter actualizada con nueva URL
- [ ] APK/IPA generado con URL de producción
- [ ] Logs no muestran errores críticos
- [ ] MongoDB Atlas acepta conexiones

---

## 🎯 Próximos Pasos

1. **Testing Completo:** Prueba todas las funcionalidades de tu app
2. **Plan de Pago:** Si todo funciona bien, considera actualizar a Starter ($7/mes) para eliminar cold starts
3. **Dominio Personalizado:** Configura `api.tudominio.com` para profesionalizar
4. **Monitoring:** Configura alertas para errores críticos
5. **Backups:** Asegúrate de tener backups de MongoDB Atlas

---

## 📞 Soporte

- **Render Docs:** https://render.com/docs
- **Render Community:** https://community.render.com
- **Status Page:** https://status.render.com

---

**¡Tu aplicación ahora está en Render! 🎉**

Creado: 26 de Enero 2026
