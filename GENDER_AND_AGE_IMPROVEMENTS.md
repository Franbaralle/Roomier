# Mejoras de Perfil: Género y Edad

## Descripción
Se implementaron dos mejoras críticas en el sistema de registro y perfiles:
1. **Selección de género propio del usuario** durante el registro
2. **Cálculo y visualización de edad** en el perfil basado en la fecha de nacimiento

## Problema Resuelto

### Antes:
- ❌ Los usuarios podían elegir con qué género querían convivir, pero no asignaban su propio género
- ❌ La fecha de nacimiento se guardaba, pero nunca se mostraba la edad calculada
- ❌ El algoritmo de matching no podía usar el género del usuario para filtrar correctamente

### Ahora:
- ✅ Nueva página de selección de género propio en el flujo de registro
- ✅ El género del usuario se guarda correctamente en la base de datos
- ✅ La edad se calcula automáticamente y se muestra en el perfil
- ✅ El algoritmo de matching puede usar correctamente ambos géneros (propio y preferido)

## Implementación

### 1. Nueva Página: `gender_selection_page.dart`

**Ubicación en el flujo de registro:**
1. Usuario hace clic en "Crear Cuenta" desde login
2. **→ Selección de Género (NUEVO)** ← Primera página del registro
3. → Fecha de Nacimiento
4. → Datos básicos (usuario, email, contraseña)
5. → Preferencias e intereses
6. → Preferencias de roommate (género PREFERIDO)
7. → Hábitos de convivencia
8. → Info de vivienda
9. → Información personal
10. → Foto de perfil

**Características:**
- 3 opciones de género: Masculino, Femenino, Otro
- Diseño consistente con el resto de la app
- Validación: no permite continuar sin seleccionar
- Guarda el género temporalmente en SharedPreferences
- Iconos intuitivos para cada opción

### 2. Cálculo de Edad en Perfil

**Funciones agregadas en `profile_page.dart`:**

```dart
// Calcula edad desde fecha de nacimiento
int? _calculateAge(String? birthdateString)

// Convierte código de género a texto legible
String _getGenderText(String? gender)
```

**Visualización:**
- **Nombre de usuario, Edad**: Ej. "Juan, 25"
- **Ícono + Género**: Muestra el ícono apropiado (👨‍🦱/👩‍🦱/👤) y el texto
- Se muestra tanto en la foto de perfil principal como en el placeholder
- Estilo consistente con sombras y efectos visuales

### 3. Actualización del Flujo de Datos

#### SharedPreferences (temporal durante registro):
```dart
'temp_register_gender' → String ('male'/'female'/'other')
```

#### Envío al Backend (en profile_photo.dart):
```dart
final registrationData = {
  'username': username,
  'password': password,
  'email': email,
  'birthdate': birthdate,
  'gender': gender, // ← NUEVO CAMPO
  'preferences': {...},
  'roommatePreferences': {...}, // Gender PREFERIDO
  ...
};
```

#### Modelo de Usuario (Backend):
El campo `gender` ya existía en el modelo de usuario (`backend/models/user.js`):
```javascript
gender: { type: String, enum: ['male', 'female', 'other'], required: false }
```

## Archivos Modificados

### Creados:
- `lib/gender_selection_page.dart` - Nueva página de selección de género

### Modificados:
- `lib/routes.dart` - Agregada ruta `genderSelectionRoute` y `dateRoute`
- `lib/main.dart` - Importada y configurada nueva página en las rutas
- `lib/login_page.dart` - Cambio de flujo: ahora va a `genderSelectionRoute` en lugar de `dateRoute`
- `lib/profile_photo.dart` - Agregado género al guardado final del registro
- `lib/profile_page.dart` - Agregadas funciones de cálculo de edad y visualización

## Flujo Visual en el Perfil

```
┌─────────────────────────────────┐
│                                 │
│    [Foto de Perfil del User]   │
│                                 │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Juan, 25                │   │
│  │ 👨‍🦱 Hombre               │   │
│  │ ✓ Email verificado      │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

## Beneficios del Sistema

### Para el Usuario:
1. **Claridad**: Ahora se ve la edad exacta en cada perfil
2. **Información completa**: Género visible ayuda a entender mejor los matches
3. **Flujo intuitivo**: La pregunta de género está al inicio, es natural

### Para el Algoritmo de Matching:
1. **Mejor filtrado**: Puede usar el género del usuario para matching bidireccional
2. **Validación**: Ambos usuarios deben cumplir las preferencias del otro
3. **Precisión**: La edad calculada permite filtros más exactos

### Para el Negocio:
1. **Datos completos**: Base de datos más rica para analytics
2. **Segmentación**: Posibilidad de analizar por género y rango de edad
3. **Compliance**: Información demográfica necesaria para reportes

## Validaciones

- ✅ No se puede continuar sin seleccionar género
- ✅ La edad se calcula correctamente considerando si ya cumplió años
- ✅ Manejo de errores si la fecha de nacimiento es inválida
- ✅ Campos opcionales se muestran solo si tienen valor
- ✅ Iconos dinámicos según el género seleccionado

## Testing Recomendado

1. **Registro completo**:
   - Crear nuevo usuario
   - Verificar que se solicite el género al inicio
   - Completar todo el flujo
   - Verificar que el género se guardó correctamente

2. **Visualización de perfil**:
   - Ver perfil propio
   - Ver perfil de otro usuario
   - Verificar que la edad se calcula correctamente
   - Verificar que el género se muestra con el ícono correcto

3. **Casos edge**:
   - Usuario sin género asignado (usuarios antiguos)
   - Usuario sin fecha de nacimiento
   - Fecha de nacimiento inválida

## Próximas Mejoras Sugeridas

1. **Edición de género**: Permitir cambiar el género desde la edición de perfil
2. **Preferencias de privacidad**: Opción de ocultar edad/género
3. **Pronombres**: Agregar campo de pronombres preferidos (él/ella/elle)
4. **Estadísticas**: Dashboard de analytics por género y edad
