# Migración a Cloudinary - Guía Completa

## 📋 Resumen

Hemos migrado el sistema de almacenamiento de imágenes de perfil desde MongoDB (Buffer) a Cloudinary (URLs). Esto optimiza el ancho de banda, reduce el tamaño de la base de datos y aprovecha el CDN global de Cloudinary.

## 🎯 Beneficios

1. **Reducción de ancho de banda**: Las imágenes se sirven desde el CDN de Cloudinary
2. **Optimización automática**: Cloudinary comprime y optimiza las imágenes automáticamente
3. **Base de datos más liviana**: Solo guardamos URLs en lugar de Buffers grandes
4. **Transformaciones on-the-fly**: Podemos redimensionar imágenes sin reprocesar
5. **CDN global**: Entrega rápida desde el servidor más cercano al usuario

## 📦 Cambios Implementados

### 1. Modelo de Usuario (`models/user.js`)
```javascript
// ANTES:
profilePhoto: { type: Buffer, required: false }

// AHORA:
profilePhoto: { type: String, required: false }, // URL de Cloudinary
profilePhotoPublicId: { type: String, required: false }, // Para eliminación
profilePhotoBuffer: { type: Buffer, required: false } // Legacy (deprecated)
```

### 2. Nuevo Servicio (`utils/cloudinary.js`)
- `uploadImage(buffer, folder, publicId)`: Sube imagen a Cloudinary
- `deleteImage(publicId)`: Elimina imagen de Cloudinary
- `extractPublicId(url)`: Extrae el public_id de una URL

### 3. Endpoints Actualizados
- ✅ `/register/profile_photo` - Sube a Cloudinary en lugar de MongoDB
- ✅ `/profile` - Devuelve URL directa (o base64 para usuarios legacy)
- ✅ `/chat/list` - Maneja URLs y Buffers legacy

## 🔧 Configuración

### 1. Crear cuenta en Cloudinary
1. Regístrate en [cloudinary.com](https://cloudinary.com)
2. Plan gratuito incluye:
   - 25 GB de almacenamiento
   - 25 GB de ancho de banda/mes
   - 25,000 transformaciones/mes

### 2. Obtener credenciales
1. Ve a **Dashboard > Settings > Access Keys**
2. Copia:
   - Cloud Name
   - API Key
   - API Secret

### 3. Configurar variables de entorno

#### Desarrollo local (`.env`):
```bash
CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret
```

#### Producción (Railway):
```bash
# En Railway dashboard:
# Settings > Variables > New Variable

CLOUDINARY_CLOUD_NAME=tu_cloud_name
CLOUDINARY_API_KEY=tu_api_key
CLOUDINARY_API_SECRET=tu_api_secret
```

## 🔄 Migración de Datos Existentes

### Opción 1: Script automático (recomendado)

```bash
# 1. Asegúrate de tener las variables de entorno configuradas
# 2. Ejecuta el script de migración
node migrateImagesToCloudinary.js
```

El script:
- Encuentra todos los usuarios con fotos en Buffer
- Sube cada foto a Cloudinary
- Actualiza el usuario con la URL
- Guarda el Buffer original en `profilePhotoBuffer` (backup)
- Muestra un resumen al final

### Opción 2: Migración gradual (producción en vivo)

Si prefieres no migrar todo de una vez:

1. El código ya es **retrocompatible**:
   - Usuarios nuevos: suben directamente a Cloudinary
   - Usuarios existentes: mantienen su Buffer hasta que actualicen su foto
   
2. Los endpoints devuelven:
   - URL de Cloudinary si existe
   - Base64 del Buffer si es usuario legacy

3. Eventualmente puedes ejecutar el script cuando haya menos tráfico

## 📊 Monitoreo

### Ver estadísticas en Cloudinary:
1. Dashboard > Media Library
2. Reports > Usage

### Verificar migración:
```javascript
// En MongoDB
db.users.find({ 
  profilePhoto: { $type: "string" } 
}).count() // Usuarios migrados

db.users.find({ 
  profilePhoto: { $type: "binData" } 
}).count() // Usuarios pendientes
```

## 🚀 Deploy en Producción

### 1. Actualizar Railway
```bash
git add .
git commit -m "feat: migrate images to Cloudinary"
git push origin main
```

### 2. Agregar variables en Railway
Settings > Variables > New Variable:
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

### 3. Verificar deployment
- Check logs: `railway logs`
- Probar subida de nueva foto
- Verificar que las URLs funcionan

### 4. Ejecutar migración (opcional)
Si quieres migrar datos existentes:
```bash
# Opción A: Localmente (con VPN a MongoDB Atlas)
node migrateImagesToCloudinary.js

# Opción B: En Railway
railway run node migrateImagesToCloudinary.js
```

## 📱 Impacto en Flutter

### Sin cambios necesarios en la app móvil

El frontend de Flutter **no necesita cambios** porque:

1. **Subida de imágenes**: Sigue enviando el mismo FormData al endpoint `/register/profile_photo`
2. **Recepción de imágenes**: 
   - Antes recibía base64 → `base64Decode()`
   - Ahora recibe URL → `NetworkImage()` o `CachedNetworkImage()`

### Mejora recomendada (opcional):
```dart
// En lugar de:
Image.memory(base64Decode(profilePhoto))

// Usar:
if (profilePhoto.startsWith('http')) {
  CachedNetworkImage(imageUrl: profilePhoto) // URL de Cloudinary
} else {
  Image.memory(base64Decode(profilePhoto)) // Legacy base64
}
```

## ⚠️ Consideraciones

### Seguridad
- ✅ Las transformaciones están configuradas para optimización automática
- ✅ Límite de 10MB por imagen (configurado en multer)
- ✅ Solo se aceptan imágenes (mime type validation)
- ⚠️ Considera agregar autenticación de API keys con restricciones de dominio

### Costos
- Plan gratuito: 25GB/mes de ancho de banda
- Si excedes: $0.09/GB adicional
- Monitorea uso en Dashboard > Reports

### Backup
- ✅ El script guarda el Buffer original en `profilePhotoBuffer`
- ⚠️ Considera eliminar buffers antiguos después de confirmar migración exitosa

## 🧹 Limpieza Post-Migración (Opcional)

Después de confirmar que la migración fue exitosa (1-2 semanas):

```javascript
// Script para eliminar buffers legacy
const User = require('./models/user');

User.updateMany(
  { profilePhotoBuffer: { $exists: true } },
  { $unset: { profilePhotoBuffer: "" } }
)
.then(result => console.log(`Eliminados ${result.modifiedCount} buffers legacy`));
```

## 🐛 Troubleshooting

### Error: "cloud_name is missing"
- Verifica que las variables de entorno estén configuradas
- Reinicia el servidor después de agregar variables

### Error: "Invalid signature"
- Verifica que el API Secret sea correcto
- No debe tener espacios ni caracteres especiales

### Imágenes no se ven en la app
- Verifica que las URLs sean públicas (no signed URLs)
- Check CORS en Cloudinary si hay problemas desde web

### Migración muy lenta
- El script procesa usuarios de uno en uno (seguro)
- Para acelerar: implementar procesamiento en paralelo (max 5 concurrentes)

## 📚 Referencias

- [Cloudinary Docs](https://cloudinary.com/documentation)
- [Node.js SDK](https://cloudinary.com/documentation/node_integration)
- [Image Transformations](https://cloudinary.com/documentation/image_transformations)
- [Upload API](https://cloudinary.com/documentation/image_upload_api_reference)

---

**¿Preguntas?** Revisa los logs en `backend/logs/` o contacta al equipo de desarrollo.
