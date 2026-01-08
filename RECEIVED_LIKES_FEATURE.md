# Funcionalidad: Likes Recibidos

## Descripción
Nueva sección que permite a los usuarios ver quiénes les dieron "like", pero con las imágenes blureadas para incentivar el uso continuo de la app o la suscripción premium.

## Características Implementadas

### Backend
1. **Endpoint**: `GET /api/home/received-likes`
   - **Ubicación**: `backend/routes/home.js`
   - **Función**: Retorna la lista de usuarios que dieron like al usuario actual pero no hay match mutuo
   - **Datos retornados**: 
     - Username
     - Edad
     - Género
     - Fotos de perfil
     - Información básica (trabajo, descripción)

### Frontend

#### 1. Nueva Página: `received_likes_page.dart`
- Muestra una grilla de perfiles con imágenes blureadas
- Cada tarjeta incluye:
  - Imagen de perfil con efecto blur (sigma: 10)
  - Overlay oscuro para mejor legibilidad
  - Icono de corazón en el centro
  - Edad del usuario
  - Trabajo (si está disponible)
  
#### 2. Popup de Premium
- Se muestra al tocar cualquier perfil blureado
- Mensaje: "Para acceder a este perfil seguí deslizando o accedé a la versión Premium de la app"
- Dos opciones:
  - **Cerrar**: Cierra el popup
  - **Ver Premium**: Placeholder para futura implementación de suscripción

#### 3. Integración en Home
- Nuevo botón en la barra de navegación inferior (ícono de corazón ❤️)
- Contador de likes recibidos (badge rojo)
- Ubicado entre el botón de boost y el de mensajes
- El contador se actualiza al regresar de la página de likes

### Servicios

#### AuthService
Nuevo método agregado en `lib/auth_service.dart`:
```dart
Future<List<dynamic>> fetchReceivedLikes(String username)
```
- Llama al endpoint del backend
- Maneja errores y retorna lista vacía en caso de fallo

## Flujo de Usuario

1. Usuario ve el ícono de corazón con un contador (ej: "3")
2. Al tocar el ícono, se abre la página de likes recibidos
3. Ve una grilla con 3 tarjetas blureadas mostrando edad y trabajo
4. Al tocar cualquier tarjeta, aparece el popup de premium
5. Usuario tiene 2 opciones:
   - Seguir deslizando en la app para eventualmente encontrar a esa persona
   - Acceder a la versión Premium (próximamente)

## Ventajas del Sistema

1. **Engagement**: Incentiva a los usuarios a seguir usando la app
2. **Monetización**: Prepara el terreno para futuras suscripciones premium
3. **Curiosidad**: Los usuarios querrán saber quién les dio like
4. **No intrusivo**: No bloquea funcionalidad principal, solo agrega valor

## Próximos Pasos Sugeridos

1. Implementar sistema de suscripción Premium
2. Permitir ver perfiles completos a usuarios premium
3. Agregar analytics para tracking de:
   - Cuántos usuarios ven la página de likes
   - Cuántos tocan los perfiles blureados
   - Conversión a premium desde el popup

## Archivos Modificados/Creados

### Creados:
- `lib/received_likes_page.dart` - Nueva página de likes recibidos

### Modificados:
- `backend/routes/home.js` - Agregado endpoint `/received-likes`
- `lib/auth_service.dart` - Agregado método `fetchReceivedLikes()`
- `lib/home.dart` - Integrado nuevo botón y contador en UI

## Testing

Para probar la funcionalidad:
1. Crear dos usuarios
2. Usuario A da like a Usuario B
3. Usuario B inicia sesión
4. Usuario B verá un contador "1" en el ícono de corazón
5. Al tocar, verá el perfil de Usuario A blureado
6. Al tocar el perfil, aparecerá el popup de premium
