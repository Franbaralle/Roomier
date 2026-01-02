# 🚀 Pasos para Deployment - Migración a Cloudinary

## ✅ Completado (Local)

1. ✅ Instaladas dependencias: `cloudinary`, `streamifier`
2. ✅ Creado servicio de Cloudinary (`utils/cloudinary.js`)
3. ✅ Actualizado modelo de Usuario (URLs en lugar de Buffer)
4. ✅ Actualizado endpoint `/register/profile_photo`
5. ✅ Actualizados endpoints de perfil y chat (retrocompatibles)
6. ✅ Creado script de migración (`migrateImagesToCloudinary.js`)
7. ✅ Documentación completa (`CLOUDINARY_MIGRATION.md`)
8. ✅ Variables de entorno documentadas (`.env.example`)

## 📋 Pendiente - Pasos para Producción

### 1️⃣ Crear Cuenta en Cloudinary (5 minutos)

1. Ir a [cloudinary.com](https://cloudinary.com) y registrarse
2. Verificar email
3. Ir a **Dashboard** (se abre automáticamente)
4. Copiar credenciales del panel:
   - **Cloud Name** (arriba a la izquierda)
   - **API Key** (en Product Environment Credentials)
   - **API Secret** (click en "Show" para ver)

### 2️⃣ Configurar Variables en Railway (3 minutos)

1. Ir al proyecto en Railway: https://railway.app
2. Click en tu servicio backend
3. Ir a **Settings** > **Variables**
4. Click en **New Variable** y agregar cada una:

```
CLOUDINARY_CLOUD_NAME=<tu_cloud_name>
CLOUDINARY_API_KEY=<tu_api_key>
CLOUDINARY_API_SECRET=<tu_api_secret>
```

5. Railway reiniciará automáticamente el servicio

### 3️⃣ Hacer Deploy del Código (2 minutos)

```bash
# Commitear y pushear los cambios
git add .
git commit -m "feat: migrate image storage to Cloudinary with CDN"
git push origin main
```

Railway detectará el push y hará deploy automáticamente.

### 4️⃣ Verificar Deployment (5 minutos)

1. **Verificar que el servicio está corriendo**:
   ```bash
   # En Railway logs
   railway logs
   ```
   Buscar: "✅ Conectado a MongoDB" (sin errores de Cloudinary)

2. **Probar subida de imagen**:
   - Crear un usuario nuevo desde la app
   - Subir una foto de perfil
   - Verificar que la foto se ve correctamente

3. **Verificar en Cloudinary**:
   - Ir a Dashboard > Media Library
   - Deberías ver la imagen en la carpeta `profile_photos`

### 5️⃣ Migrar Imágenes Existentes (10-30 minutos)

**Opción A: Ejecutar localmente con VPN a MongoDB Atlas**

```bash
# 1. Asegúrate de tener las variables en tu .env local:
CLOUDINARY_CLOUD_NAME=<tu_cloud_name>
CLOUDINARY_API_KEY=<tu_api_key>
CLOUDINARY_API_SECRET=<tu_api_secret>
MONGODB_URI=<tu_uri_de_atlas>

# 2. Ejecutar migración
node migrateImagesToCloudinary.js
```

**Opción B: Ejecutar en Railway (recomendado)**

```bash
# Desde tu terminal local
railway run node migrateImagesToCloudinary.js
```

**Opción C: No migrar aún (migración gradual)**

- Los usuarios con fotos viejas seguirán funcionando (base64)
- Los usuarios nuevos subirán directamente a Cloudinary
- Puedes migrar más adelante cuando haya menos tráfico

### 6️⃣ Verificar Migración (5 minutos)

1. **Verificar en MongoDB**:
   ```javascript
   // Usuarios migrados (tienen URL de String)
   db.users.find({ 
     profilePhoto: { $type: "string", $regex: "cloudinary" } 
   }).count()

   // Usuarios pendientes (tienen Buffer)
   db.users.find({ 
     profilePhoto: { $type: "binData" } 
   }).count()
   ```

2. **Verificar en Cloudinary**:
   - Dashboard > Media Library
   - Deberías ver todas las fotos migradas

3. **Probar en la app**:
   - Abrir perfiles de usuarios existentes
   - Verificar que las fotos se cargan correctamente

### 7️⃣ Monitoreo Post-Deployment (Primeros días)

1. **Cloudinary Usage**:
   - Dashboard > Reports > Usage
   - Verificar que no excedes el plan gratuito

2. **Logs de Railway**:
   ```bash
   railway logs --filter "cloudinary"
   ```
   Verificar que no haya errores

3. **Rendimiento**:
   - Las imágenes deberían cargar más rápido
   - La DB debería estar más liviana

## 🐛 Troubleshooting

### Error: "cloud_name is missing"
- Verificar que las variables estén en Railway
- Verificar que no tengan espacios ni comillas extras
- Reiniciar el servicio en Railway

### Error: "Invalid signature"
- Verificar que el API Secret sea correcto
- Copiar y pegar directamente desde Cloudinary

### Imágenes no se ven en la app
- Verificar que las URLs sean públicas (no signed)
- Check logs de Railway para ver errores
- Verificar que el endpoint devuelve la URL correcta

### Migración muy lenta
- Normal si hay muchos usuarios
- El script procesa de uno en uno por seguridad
- Puedes pausar y reanudar cuando quieras

## 📊 Beneficios Esperados

### Antes (MongoDB Buffer):
- Imagen de 2MB = 2.66MB en base64
- Cada request carga la imagen completa
- Sin optimización ni compresión
- Sin CDN (latencia alta)

### Después (Cloudinary):
- Imagen de 2MB → ~200KB optimizada
- CDN global (latencia baja)
- Redimensionada automáticamente
- Formato WebP cuando es soportado
- Ancho de banda reducido en ~90%

## 🎯 KPIs para Monitorear

1. **Tamaño de DB**: Debería reducirse significativamente
2. **Tiempo de carga de imágenes**: ~5x más rápido
3. **Uso de ancho de banda**: ~90% menos en Railway
4. **Cloudinary usage**: Mantenerse bajo 25GB/mes

## 📚 Referencias

- Documentación detallada: `backend/CLOUDINARY_MIGRATION.md`
- Variables de entorno: `backend/.env.example`
- Script de migración: `backend/migrateImagesToCloudinary.js`

---

**¿Problemas?** Revisa los logs o consulta la documentación completa.
