# Sistema de Preferencias con Categorías - Documentación

## 📋 Resumen
Se ha implementado un sistema robusto de preferencias categorizadas que permite a los usuarios seleccionar hasta 5 tags por subcategoría, organizados en 6 categorías principales con múltiples subcategorías.

## 🏗️ Arquitectura Implementada

### Backend (Node.js/MongoDB)

#### Modelo de Usuario Actualizado
**Archivo**: `backend/models/User.js`

```javascript
preferences: {
  convivencia: {
    hogar: [String],     // Máx 5 tags
    social: [String],    // Máx 5 tags
    mascotas: [String]   // Máx 5 tags
  },
  gastronomia: {
    habitos: [String],
    bebidas: [String],
    habilidades: [String]
  },
  deporte: {
    intensidad: [String],
    menteCuerpo: [String],
    deportesPelota: [String],
    aguaNaturaleza: [String]
  },
  entretenimiento: {
    pantalla: [String],
    musica: [String],
    gaming: [String]
  },
  creatividad: {
    artesPlasticas: [String],
    tecnologia: [String],
    moda: [String]
  },
  interesesSociales: {
    causas: [String],
    conocimiento: [String]
  }
}
```

#### Endpoint de Registro de Preferencias
**Archivo**: `backend/routes/register.js`

- **Ruta**: `POST /api/register/preferences`
- **Validación**: 
  - Estructura de objeto jerárquico
  - Máximo 5 tags por subcategoría
  - Validación de categorías y subcategorías válidas
- **Formato de Request**:
```json
{
  "username": "usuario123",
  "preferences": {
    "convivencia": {
      "hogar": ["plantas_jardineria", "decoracion_interiores"],
      "social": ["anfitrion_cenas"],
      "mascotas": ["dog_lover"]
    },
    "gastronomia": {
      "habitos": ["vegetariana", "meal_prep"],
      "bebidas": ["cafe_especialidad"],
      "habilidades": []
    }
    // ... resto de categorías
  }
}
```

#### Algoritmo de Compatibilidad Actualizado
**Archivo**: `backend/routes/home.js`

- Calcula compatibilidad basada en tags comunes
- Recorre todas las categorías y subcategorías
- Fórmula: `(tags_comunes / max(tags_A, tags_B)) * 100`
- Peso en score total: 15%

### Frontend (Flutter)

#### Archivo de Datos: `lib/preferences_data.dart`
Contiene:
- **categories**: Estructura completa de todas las categorías, subcategorías y tags
- **tagLabels**: Mapeo de IDs a nombres con emojis (ej: `'yoga': '🧘 Yoga'`)
- **categoryLabels**: Nombres de categorías principales
- **subcategoryLabels**: Nombres de subcategorías

**Total de tags disponibles**: ~150 opciones

#### UI Moderna: `lib/preferences.dart`
**Características**:
- ✅ Categorías expandibles (ExpansionPanel style)
- ✅ Chips seleccionables con `FilterChip`
- ✅ Contador de tags por subcategoría (X/5)
- ✅ Contador total de tags seleccionados
- ✅ Validación de límite de 5 tags por subcategoría
- ✅ Notificación cuando se alcanza el límite
- ✅ Diseño responsive con `Wrap` para los chips
- ✅ Colores y elevaciones dinámicas según selección

#### Auth Service Actualizado
**Archivo**: `lib/auth_service.dart`

```dart
Future<void> updatePreferences(
  String username, 
  Map<String, Map<String, List<String>>> preferences
) async
```

## 📊 Categorías Implementadas

### 🏠 Convivencia y Estilo de Vida
- **Hogar**: 6 tags (Plantas, Decoración, DIY, Minimalismo, Organización, Feng Shui)
- **Social**: 6 tags (Cenas, Salidas, Planes tranquilos, Club lectura, Juegos, Karaoke)
- **Mascotas**: 5 tags (Dog/Cat lover, Rescate, Exóticos, Alergias)

### 🍳 Gastronomía y Nutrición
- **Hábitos**: 6 tags (Vegetariana, Vegana, Celíacos, Meal prep, Saludable, Foodie)
- **Bebidas**: 5 tags (Café, Té/Mate, Cerveza, Coctelería, Vino)
- **Habilidades**: 4 tags (Repostería, Asado, Internacional, Panadería)

### 🏃 Deporte y Bienestar
- **Intensidad**: 5 tags (Gimnasio, CrossFit, Calistenia, Running, Ciclismo)
- **Mente y Cuerpo**: 5 tags (Yoga, Meditación, Pilates, Salud mental, Espiritualidad)
- **Deportes de Pelota**: 6 tags (Fútbol, Básquet, Vóley, Pádel, Tenis, Rugby)
- **Agua/Naturaleza**: 6 tags (Trekking, Surf, Natación, Buceo, Escalada, Camping)

### 🎭 Entretenimiento y Ocio
- **Pantalla**: 6 tags (Cine indie, Documentales, True Crime, Anime, Sci-Fi, Reality)
- **Música**: 9 tags (Conciertos, Festivales, Instrumento, Producción, Vinilos, Jazz, Techno, Rock, Urbano)
- **Gaming**: 5 tags (Competitivos, Rol, Streamers, E-sports, Retro)

### 🧠 Creatividad y Tecnología
- **Artes Plásticas**: 5 tags (Dibujo, Alfarería, Fotografía, Diseño, Tatuajes)
- **Tecnología**: 5 tags (Programación, IA, Crypto, Gadgets, Robótica)
- **Moda**: 4 tags (Upcycling, Vintage, Diseño moda, Maquillaje)

### 🌍 Intereses Sociales y Conocimiento
- **Causas**: 6 tags (Activismo, Voluntariado, Feminismo, DDHH, Política, Sostenibilidad)
- **Conocimiento**: 7 tags (Idiomas, Historia, Filosofía, Psicología, Astrología, Astronomía, Finanzas)

## 🔄 Migración de Datos

### Campo Legacy
Se mantiene `legacyPreferences: [String]` para migración gradual de usuarios existentes.

### Script de Migración Recomendado
Crear `backend/scripts/migratePreferences.js`:

```javascript
const User = require('../models/User');

async function migratePreferences() {
  const users = await User.find({ legacyPreferences: { $exists: true, $ne: [] } });
  
  for (const user of users) {
    // Mapear preferences antiguas a nueva estructura
    const mappedPrefs = mapLegacyToNew(user.legacyPreferences);
    user.preferences = mappedPrefs;
    await user.save();
  }
}

function mapLegacyToNew(oldPrefs) {
  // Mapeo manual según tags antiguas
  const mapping = {
    'Trekking': ['deporte', 'aguaNaturaleza', 'trekking'],
    'Cocina': ['gastronomia', 'habilidades', 'cocina_internacional'],
    // ... resto de mapeos
  };
  
  const newPrefs = initializeEmptyPreferences();
  
  oldPrefs.forEach(oldTag => {
    const [mainCat, subCat, newTag] = mapping[oldTag] || [];
    if (mainCat && subCat && newTag) {
      newPrefs[mainCat][subCat].push(newTag);
    }
  });
  
  return newPrefs;
}
```

## 🧪 Testing

### Probar Backend
```bash
curl -X POST http://localhost:3000/api/register/preferences \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "preferences": {
      "convivencia": {
        "hogar": ["plantas_jardineria"],
        "social": ["anfitrion_cenas"],
        "mascotas": []
      },
      "gastronomia": {
        "habitos": ["vegetariana"],
        "bebidas": [],
        "habilidades": []
      }
    }
  }'
```

### Probar Flutter
1. Ejecutar app en desarrollo
2. Ir a pantalla de preferencias durante registro
3. Expandir categorías
4. Seleccionar tags (verificar límite de 5)
5. Verificar contador total
6. Continuar y verificar que se guarden correctamente

## 📝 Notas Técnicas

### Ventajas del Nuevo Sistema
✅ **Escalabilidad**: Fácil agregar nuevas categorías/tags en `preferences_data.dart`  
✅ **UX Mejorada**: Interfaz intuitiva con chips visuales  
✅ **Mejor Matching**: Algoritmo más preciso con más datos  
✅ **Internacionalización**: IDs separados de labels (preparado para multi-idioma)  
✅ **Performance**: MongoDB consultas eficientes con estructura anidada  

### Consideraciones
⚠️ **Migración**: Usuarios existentes necesitarán actualizar preferencias  
⚠️ **Tamaño de Documento**: Cada usuario puede tener ~150 tags máximo (75 KB aprox)  
⚠️ **Índices**: Considerar índices en MongoDB para búsquedas de compatibilidad

### Próximos Pasos Sugeridos
1. Implementar script de migración
2. Agregar filtros de búsqueda por tags
3. Mostrar tags comunes en pantalla de perfil
4. Implementar sistema de búsqueda de roommates por tags
5. Analytics de tags más populares

## 🎨 Capturas de UI (Ejemplo de Flujo)
```
┌─────────────────────────────────┐
│    Tus Intereses        [←]     │
├─────────────────────────────────┤
│ Selecciona hasta 5 tags por     │
│      subcategoría               │
│                                 │
│     [  12 tags seleccionados  ] │
├─────────────────────────────────┤
│ 🏠 Convivencia y Estilo...  [▼] │
│   Hogar               [2/5]     │
│   [🌿 Plantas] [🏠 Decoración]  │
│   [ DIY ] [ Minimalismo ]...    │
│                                 │
│   Social              [1/5]     │
│   [🍽️ Anfitrión] [ Salidas ]   │
│                                 │
├─────────────────────────────────┤
│ 🍳 Gastronomía...          [▶]  │
├─────────────────────────────────┤
│         [  Continuar  ]         │
└─────────────────────────────────┘
```

## 🔗 Archivos Modificados
- ✅ `backend/models/User.js`
- ✅ `backend/routes/register.js`
- ✅ `backend/routes/home.js`
- ✅ `lib/preferences_data.dart` (nuevo)
- ✅ `lib/preferences.dart`
- ✅ `lib/auth_service.dart`

---
**Última actualización**: 5 de enero de 2026
