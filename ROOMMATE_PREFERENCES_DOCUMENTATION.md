# Preferencias de Roommate - Documentación

## 📋 Resumen
Se ha implementado un sistema de preferencias de roommate que permite a los usuarios especificar:
- **Género preferido del roommate**: Hombre, Mujer o Ambos
- **Rango de edad**: Edad mínima y máxima para convivir

Este sistema actúa como un filtro previo al matching, evitando que se muestren candidatos que no cumplan con las preferencias básicas del usuario.

## 🏗️ Arquitectura

### Backend

#### 1. Modelo de Usuario Actualizado
**Archivo**: `backend/models/User.js`

```javascript
// Campo de género del usuario
gender: { 
  type: String, 
  enum: ['male', 'female', 'other'], 
  required: false 
}

// Preferencias de roommate
roommatePreferences: {
  gender: { 
    type: String, 
    enum: ['male', 'female', 'both'], 
    default: 'both' 
  },
  ageMin: { 
    type: Number, 
    min: 18, 
    max: 100, 
    required: false 
  },
  ageMax: { 
    type: Number, 
    min: 18, 
    max: 100, 
    required: false 
  }
}
```

#### 2. Endpoint de Registro
**Archivo**: `backend/routes/register.js`

**Ruta**: `POST /api/register/roommate-preferences`

**Request Body**:
```json
{
  "username": "usuario123",
  "gender": "both",
  "ageMin": 22,
  "ageMax": 35
}
```

**Validaciones**:
- ✅ Género debe ser: `male`, `female` o `both`
- ✅ Edad mínima: 18-100
- ✅ Edad máxima: 18-100
- ✅ Edad mínima ≤ Edad máxima

**Response Exitoso (200)**:
```json
{
  "message": "Preferencias de roommate actualizadas exitosamente",
  "roommatePreferences": {
    "gender": "both",
    "ageMin": 22,
    "ageMax": 35
  }
}
```

#### 3. Algoritmo de Matching Actualizado
**Archivo**: `backend/routes/home.js`

Se agregaron dos nuevas funciones:

##### `checkRoommatePreferences(userA, userB)`
Verifica si dos usuarios son compatibles según sus preferencias de roommate:

1. **Filtro de Género**:
   - Si A prefiere `male`, B debe ser `male`
   - Si A prefiere `female`, B debe ser `female`
   - Si A prefiere `both`, se acepta cualquier género
   - Se verifica en ambas direcciones (A→B y B→A)

2. **Filtro de Edad**:
   - Calcula la edad de cada usuario desde su fecha de nacimiento
   - Verifica que la edad esté dentro del rango especificado
   - Se verifica en ambas direcciones

##### `calculateAge(birthdate)`
Función auxiliar que calcula la edad actual del usuario:
```javascript
function calculateAge(birthdate) {
  const today = new Date();
  const birth = new Date(birthdate);
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
}
```

**Integración en el Filtrado**:
```javascript
potentialMatches = potentialMatches.filter(user => {
  // Deal breakers
  if (!checkDealBreakers(currentUser, user)) return false;
  
  // Preferencias de roommate (NUEVO)
  if (!checkRoommatePreferences(currentUser, user)) return false;
  
  // Compatibilidad de presupuesto
  if (!checkBudgetCompatibility(currentUser, user)) return false;
  
  return true;
});
```

### Frontend (Flutter)

#### 1. Pantalla de Preferencias de Roommate
**Archivo**: `lib/roommate_preferences_page.dart`

**Características de la UI**:
- 🎨 Diseño coherente con el resto de la app
- 📊 3 opciones de género con iconos visuales
- 📏 RangeSlider para seleccionar edad (18-100)
- ✅ Validación en tiempo real
- 🔔 Feedback visual de selección

**Componentes Principales**:

1. **Selector de Género**:
```dart
_buildGenderOption('Hombres', 'male', Icons.man)
_buildGenderOption('Mujeres', 'female', Icons.woman)
_buildGenderOption('Ambos', 'both', Icons.people)
```

2. **Selector de Rango de Edad**:
```dart
RangeSlider(
  values: RangeValues(minAge, maxAge),
  min: 18,
  max: 100,
  divisions: 82,
  onChanged: (RangeValues values) {
    setState(() {
      minAge = values.start;
      maxAge = values.end;
    });
  },
)
```

3. **Validación**:
```dart
bool _canContinue() {
  return selectedGender != null && minAge <= maxAge;
}
```

#### 2. Auth Service Actualizado
**Archivo**: `lib/auth_service.dart`

```dart
Future<void> updateRoommatePreferences(
  String username,
  String gender,
  int ageMin,
  int ageMax,
) async {
  final response = await http.post(
    Uri.parse('$api/register/roommate-preferences'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'username': username,
      'gender': gender,
      'ageMin': ageMin,
      'ageMax': ageMax,
    }),
  );
  // ... manejo de respuesta
}
```

#### 3. Integración en Flujo de Registro
**Archivo**: `lib/routes.dart`
```dart
const String roommatePreferencesRoute = '/register/roommate-preferences';
```

**Archivo**: `lib/main.dart`
```dart
roommatePreferencesRoute: (context) {
  final arguments = ModalRoute.of(context)!.settings.arguments;
  if (arguments != null && arguments is Map<String, dynamic>) {
    return RoommatePreferencesPage(
      username: arguments['username'],
      email: arguments['email']
    );
  }
  return RoommatePreferencesPage(username: '', email: '');
}
```

**Flujo Actualizado de Registro**:
```
1. Fecha de Nacimiento (date.dart)
2. Datos básicos (register.dart)
3. Preferencias de Intereses (preferences.dart) ← Categorías con tags
4. Preferencias de Roommate (roommate_preferences_page.dart) ← NUEVO
5. Hábitos de Convivencia (living_habits_page.dart)
6. Información de Vivienda (housing_info_page.dart)
7. Información Personal (personal_info.dart)
8. Foto de Perfil (profile_photo.dart)
9. Verificación Email (email_confirmation_page.dart)
```

## 🎯 Casos de Uso

### Ejemplo 1: Mujer busca solo mujeres de 25-30 años
```javascript
// Usuario A
{
  username: "ana_lopez",
  gender: "female",
  birthdate: "1995-03-15", // 31 años
  roommatePreferences: {
    gender: "female",
    ageMin: 25,
    ageMax: 30
  }
}

// Usuario B - ❌ NO MATCH (edad fuera del rango)
{
  username: "maria_garcia",
  gender: "female",
  birthdate: "1993-05-20" // 32 años
}

// Usuario C - ✅ MATCH
{
  username: "laura_martinez",
  gender: "female",
  birthdate: "1997-08-10" // 28 años
}
```

### Ejemplo 2: Hombre acepta ambos géneros, 22-45 años
```javascript
{
  username: "carlos_ruiz",
  gender: "male",
  birthdate: "1990-11-05",
  roommatePreferences: {
    gender: "both",
    ageMin: 22,
    ageMax: 45
  }
}
// Acepta: hombres y mujeres entre 22-45 años
```

### Ejemplo 3: Filtrado bidireccional
```javascript
// Usuario A
{
  username: "user_a",
  gender: "male",
  birthdate: "1995-01-01", // 31 años
  roommatePreferences: {
    gender: "both",    // ✅ Acepta a B (female)
    ageMin: 20,
    ageMax: 35         // ✅ B tiene 28 años
  }
}

// Usuario B
{
  username: "user_b",
  gender: "female",
  birthdate: "1996-06-15", // 28 años
  roommatePreferences: {
    gender: "male",    // ✅ Acepta a A (male)
    ageMin: 25,
    ageMax: 40         // ✅ A tiene 31 años
  }
}

// Resultado: ✅ MATCH mutuo
```

## 🧪 Testing

### Backend
```bash
# Test 1: Crear preferencias válidas
curl -X POST http://localhost:3000/api/register/roommate-preferences \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "gender": "both",
    "ageMin": 22,
    "ageMax": 35
  }'

# Test 2: Género inválido
curl -X POST http://localhost:3000/api/register/roommate-preferences \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "gender": "invalid",
    "ageMin": 22,
    "ageMax": 35
  }'
# Esperado: 400 Bad Request

# Test 3: Edad mínima > edad máxima
curl -X POST http://localhost:3000/api/register/roommate-preferences \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "gender": "both",
    "ageMin": 40,
    "ageMax": 25
  }'
# Esperado: 400 Bad Request
```

### Flutter
1. Ejecutar app
2. Completar registro hasta preferencias de roommate
3. Verificar:
   - ✅ Selección de género funciona
   - ✅ Slider de edad se mueve correctamente
   - ✅ Contador muestra "De X años a Y años"
   - ✅ Botón deshabilitado si minAge > maxAge
   - ✅ Navega a living_habits_page al continuar

### Algoritmo de Matching
```javascript
// Crear usuarios de prueba
const userA = {
  username: "test_a",
  gender: "male",
  birthdate: new Date("1995-06-15"),
  roommatePreferences: { gender: "female", ageMin: 25, ageMax: 35 }
};

const userB = {
  username: "test_b",
  gender: "female",
  birthdate: new Date("1997-03-20"), // 28 años
  roommatePreferences: { gender: "both", ageMin: 20, ageMax: 40 }
};

// Verificar
console.log(checkRoommatePreferences(userA, userB)); // true
console.log(calculateAge(userB.birthdate)); // 28
```

## 📊 Base de Datos

### Migración de Usuarios Existentes
Los usuarios existentes sin `roommatePreferences` tendrán valores por defecto:
```javascript
{
  gender: 'both',  // Acepta cualquier género
  ageMin: 18,      // Edad mínima por defecto
  ageMax: 100      // Sin límite superior
}
```

**Script de Migración** (opcional):
```javascript
// backend/scripts/migrateRoommatePreferences.js
const User = require('../models/User');

async function migrateRoommatePreferences() {
  const users = await User.find({ 
    roommatePreferences: { $exists: false } 
  });
  
  for (const user of users) {
    user.roommatePreferences = {
      gender: 'both',
      ageMin: 18,
      ageMax: 100
    };
    await user.save();
  }
  
  console.log(`Migrados ${users.length} usuarios`);
}
```

## 🎨 Capturas de UI (Ejemplo)

```
┌─────────────────────────────────┐
│ Preferencias de Roommate  [←]   │
├─────────────────────────────────┤
│          👥                      │
│  ¿Con quién te gustaría         │
│      convivir?                  │
│                                 │
│  Esto nos ayudará a encontrar   │
│  el mejor match para ti         │
├─────────────────────────────────┤
│ Género preferido                │
│                                 │
│ ┌─────────────────────────┐    │
│ │ 👨 Hombres          ○   │    │
│ └─────────────────────────┘    │
│ ┌─────────────────────────┐    │
│ │ 👩 Mujeres          ○   │    │
│ └─────────────────────────┘    │
│ ┌─────────────────────────┐    │
│ │ 👥 Ambos            ✓   │    │
│ └─────────────────────────┘    │
│                                 │
│ Rango de edad                   │
│ ┌─────────────────────────┐    │
│ │  De 22 años  a 35 años  │    │
│ │  ●━━━━━━━━━━━━━●        │    │
│ │  18          50      100│    │
│ └─────────────────────────┘    │
│                                 │
│      [    Continuar    ]        │
└─────────────────────────────────┘
```

## 🔗 Archivos Modificados/Creados

### Backend
- ✅ `backend/models/User.js` (modificado)
- ✅ `backend/routes/register.js` (modificado)
- ✅ `backend/routes/home.js` (modificado)

### Frontend
- ✅ `lib/roommate_preferences_page.dart` (nuevo)
- ✅ `lib/auth_service.dart` (modificado)
- ✅ `lib/routes.dart` (modificado)
- ✅ `lib/main.dart` (modificado)
- ✅ `lib/preferences.dart` (modificado - flujo)

## 💡 Mejoras Futuras

1. **Género No Binario**: Agregar opción `other` o `non-binary` en preferencias
2. **Preferencias Editables**: Permitir cambiar preferencias desde perfil
3. **Estadísticas**: Mostrar "X candidatos cumplen tus preferencias"
4. **Flexibilidad**: Permitir "excepciones" si hay muy pocos matches
5. **Analytics**: Trackear qué filtros son más usados

---
**Última actualización**: 5 de enero de 2026
