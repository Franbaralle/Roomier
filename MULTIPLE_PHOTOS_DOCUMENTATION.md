# Sistema de Múltiples Fotos - Roomier

## 📸 Descripción General

Sistema completo para gestionar múltiples fotos de perfil y fotos del hogar en Roomier, con almacenamiento en Cloudinary CDN.

---

## 🎯 Características Implementadas

### Fotos de Perfil
- **Límite**: Hasta 10 fotos por usuario
- **Foto Principal**: Una foto marcada como principal (aparece en matches y chats)
- **Gestión Completa**: Agregar, eliminar, cambiar principal
- **Upload Múltiple**: Subir varias fotos a la vez

### Fotos del Hogar
- **Disponibilidad**: Solo para usuarios que tienen lugar (`hasPlace = true`)
- **Límite**: Ilimitadas
- **Descripciones**: Cada foto puede tener una descripción opcional
- **Gestión Completa**: Agregar, eliminar, editar descripciones

---

## 🏗️ Arquitectura

### Backend (Node.js + Express)

#### Modelo de Datos (`backend/models/User.js`)

```javascript
// Fotos de perfil (hasta 10)
profilePhotos: [{
  url: String,           // URL de Cloudinary
  publicId: String,      // ID para eliminación en Cloudinary
  isPrimary: Boolean     // Marca la foto principal
}]

// Fotos del hogar (ilimitadas)
homePhotos: [{
  url: String,           // URL de Cloudinary
  publicId: String,      // ID para eliminación
  description: String    // Descripción opcional
}]

// Campos legacy (retrocompatibilidad)
profilePhoto: String               // URL de la foto principal
profilePhotoPublicId: String       // ID de la foto principal
```

#### Rutas API (`backend/routes/photos.js`)

**Fotos de Perfil:**
- `POST /api/photos/profile` - Agregar fotos (multipart, hasta 10 archivos)
- `GET /api/photos/profile/:username` - Obtener fotos de un usuario
- `DELETE /api/photos/profile/:publicId` - Eliminar una foto
- `PUT /api/photos/profile/:publicId/primary` - Establecer foto principal

**Fotos del Hogar:**
- `POST /api/photos/home` - Agregar fotos (multipart, hasta 50 archivos)
- `GET /api/photos/home/:username` - Obtener fotos del hogar
- `DELETE /api/photos/home/:publicId` - Eliminar una foto
- `PUT /api/photos/home/:publicId/description` - Actualizar descripción

**Autenticación:**
- Todos los endpoints POST/PUT/DELETE requieren token JWT
- Los GET son públicos (para ver perfiles de otros usuarios)

**Validaciones:**
- Máximo 10 fotos de perfil total
- Fotos del hogar solo si `hasPlace = true`
- Solo imágenes permitidas (MIME type validation)
- Máximo 10MB por archivo

---

### Frontend (Flutter)

#### Servicio (`lib/photo_service.dart`)

```dart
// Fotos de Perfil
PhotoService.uploadProfilePhotos(username, List<Uint8List>)
PhotoService.getProfilePhotos(username)
PhotoService.deleteProfilePhoto(publicId)
PhotoService.setPrimaryPhoto(publicId)

// Fotos del Hogar
PhotoService.uploadHomePhotos(username, List<Uint8List>, descriptions?)
PhotoService.getHomePhotos(username)
PhotoService.deleteHomePhoto(publicId)
PhotoService.updateHomePhotoDescription(publicId, description)
```

#### Páginas

**1. `ManageProfilePhotosPage`**
- **Ruta**: `/manage-profile-photos`
- **Acceso**: Solo usuario autenticado (propio perfil)
- **Features**:
  - Selector múltiple de imágenes (image_picker)
  - Grid de 2 columnas con las fotos actuales
  - Badge "PRINCIPAL" en la foto principal
  - Botones: "Establecer como Principal" y "Eliminar"
  - Contador de fotos (X de 10)
  - Botón "Agregar" (deshabilitado si tiene 10)

**2. `ManageHomePhotosPage`**
- **Ruta**: `/manage-home-photos`
- **Acceso**: Solo usuario autenticado con `hasPlace = true`
- **Features**:
  - Selector múltiple de imágenes
  - Grid de 2 columnas
  - Diálogo opcional para agregar descripciones
  - Botones: "Editar descripción" y "Eliminar"
  - Contador de fotos
  - Mensaje informativo si no tiene lugar

**3. Integración en `ProfilePage`**
- Dos botones nuevos debajo de "Editar Perfil":
  - **"Mis Fotos"** (morado): Navega a `ManageProfilePhotosPage`
  - **"Mi Hogar"** (teal/gris): Navega a `ManageHomePhotosPage`
    - Teal si `hasPlace = true`
    - Gris si `hasPlace = false`

---

## 🚀 Flujo de Usuario

### Agregar Fotos de Perfil

1. Usuario va a su perfil
2. Toca botón **"Mis Fotos"**
3. Toca **"Agregar"**
4. Selecciona hasta (10 - fotos_actuales) imágenes
5. Las fotos se suben automáticamente a Cloudinary
6. La primera foto agregada se marca como principal
7. Usuario puede cambiar cual es la principal

### Agregar Fotos del Hogar

1. Usuario va a su perfil
2. Toca botón **"Mi Hogar"**
3. Si no tiene lugar: Ve mensaje "No disponible"
4. Si tiene lugar:
   - Toca **"Agregar"**
   - Selecciona múltiples imágenes
   - (Opcional) Agrega descripciones
   - Las fotos se suben a Cloudinary

---

## 🔧 Configuración Técnica

### Cloudinary

**Folders utilizados:**
- `profile_photos/` - Fotos de perfil
- `home_photos/` - Fotos del hogar

**Transformaciones automáticas:**
```javascript
{
  width: 500,
  height: 500,
  crop: 'fill',
  gravity: 'face',
  quality: 'auto:good',
  fetch_format: 'auto'
}
```

**Naming convention:**
- Perfil: `user_{username}_{timestamp}_{index}`
- Hogar: `home_{username}_{timestamp}_{index}`

### Multer Configuration

```javascript
const storage = multer.memoryStorage();
const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024,  // 10MB
    files: 10                     // Máx 10 archivos simultáneos
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Solo imágenes'), false);
    }
  }
});
```

---

## 📱 Testing

### Backend

```bash
cd backend

# Test upload de foto de perfil
curl -X POST http://localhost:3000/api/photos/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "photos=@foto1.jpg" \
  -F "photos=@foto2.jpg" \
  -F "username=test_user"

# Test obtener fotos
curl http://localhost:3000/api/photos/profile/test_user

# Test establecer como principal
curl -X PUT http://localhost:3000/api/photos/profile/PUBLIC_ID/primary \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test eliminar foto
curl -X DELETE http://localhost:3000/api/photos/profile/PUBLIC_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Flutter

```bash
# Ejecutar en emulador
flutter run -d emulator-5554

# Analizar código
flutter analyze

# Hot reload
r

# Hot restart
R
```

**Pasos de testing manual:**
1. Login con usuario de prueba
2. Ir a perfil propio
3. Tocar "Mis Fotos"
4. Agregar 2-3 fotos
5. Cambiar foto principal
6. Eliminar una foto
7. Verificar que la foto principal se actualiza en el perfil
8. Tocar "Mi Hogar" (si hasPlace=true)
9. Agregar fotos con descripciones
10. Editar una descripción
11. Eliminar una foto

---

## 🐛 Troubleshooting

### Error: "Ya tienes 10 fotos de perfil"
- **Causa**: Usuario intentó agregar más de 10 fotos
- **Solución**: Eliminar fotos existentes antes de agregar nuevas

### Error: "Solo puedes subir fotos del hogar si tienes lugar"
- **Causa**: `housingInfo.hasPlace = false`
- **Solución**: El usuario debe editar su perfil y marcar que tiene lugar

### Error: "No hay token de autenticación"
- **Causa**: Token JWT no está en SharedPreferences
- **Solución**: Hacer logout y login nuevamente

### Error: "Image loading failed" en Flutter
- **Causa**: URL de Cloudinary inválida o red lenta
- **Solución**: Verificar conectividad, revisar logs de backend

### Error: "Multer file size exceeded"
- **Causa**: Imagen supera los 10MB
- **Solución**: Comprimir imagen antes de subir

---

## 🔄 Retrocompatibilidad

El sistema mantiene retrocompatibilidad con usuarios legacy que solo tienen `profilePhoto` (String):

```javascript
// Backend: Al obtener fotos de un usuario legacy
if (!user.profilePhotos || user.profilePhotos.length === 0) {
  if (user.profilePhoto) {
    return [{
      url: user.profilePhoto,
      publicId: user.profilePhotoPublicId || '',
      isPrimary: true
    }];
  }
}
```

**Migración automática:**
- Cuando un usuario legacy sube una foto nueva, se crea el array `profilePhotos`
- La foto legacy se mantiene en `profilePhoto` por compatibilidad
- Nuevas fotos se agregan solo al array

---

## 📊 Rendimiento

### Optimizaciones Implementadas

1. **Cloudinary CDN**: Todas las imágenes se sirven desde CDN global
2. **Transformaciones automáticas**: Redimensión a 500x500 en el servidor
3. **Formato automático**: WebP cuando es soportado
4. **Calidad automática**: Optimización inteligente de calidad
5. **Lazy loading**: Flutter carga imágenes bajo demanda
6. **Caché del navegador**: URLs de Cloudinary incluyen caché headers

### Límites del Plan Gratuito de Cloudinary

- 25 GB de almacenamiento
- 25 GB de ancho de banda/mes
- 25,000 transformaciones/mes
- CDN global incluido

---

## 🚧 Próximas Mejoras

### Corto Plazo
- [ ] Visor de galería en pantalla completa (zoom, swipe)
- [ ] Reordenar fotos (drag & drop)
- [ ] Filtros/efectos antes de subir
- [ ] Compresión client-side antes de upload

### Mediano Plazo
- [ ] Mostrar fotos en cards de matching
- [ ] Galería en página de perfil público
- [ ] Estadísticas de vistas de fotos
- [ ] Moderación automática de contenido (ML)

### Largo Plazo
- [ ] Videos cortos de presentación
- [ ] Tours virtuales 360° del hogar
- [ ] Reconocimiento facial para sugerencias
- [ ] Integración con Instagram/Facebook

---

## 📝 Notas Importantes

1. **Privacidad**: Las fotos de perfil son públicas (otros usuarios las ven en matches)
2. **Fotos del hogar**: Solo visibles después de match mutuo
3. **Moderación**: Administradores pueden ver todas las fotos
4. **Eliminación**: Al eliminar usuario, se eliminan todas sus fotos de Cloudinary
5. **GDPR**: Usuario puede solicitar eliminación de todas sus fotos

---

## 🔗 Referencias

- [Cloudinary Docs](https://cloudinary.com/documentation)
- [Multer Docs](https://github.com/expressjs/multer)
- [Image Picker Flutter](https://pub.dev/packages/image_picker)
- [Backend: routes/photos.js](../backend/routes/photos.js)
- [Frontend: photo_service.dart](../lib/photo_service.dart)

---

**Última actualización**: 3 de Enero de 2026
**Autor**: GitHub Copilot + Roomier Team
**Versión**: 1.0.0
