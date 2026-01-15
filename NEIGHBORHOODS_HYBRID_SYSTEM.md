# Sistema Híbrido de Barrios - OpenStreetMap + Texto Libre

## 📋 Resumen

Implementación de un sistema inteligente para la selección de barrios que:
- ✅ **Usa datos estructurados** (OSM) en ciudades grandes (CABA, Córdoba, etc.)
- ✅ **Permite texto libre** en ciudades sin datos cargados
- ✅ **Escala automáticamente** sin trabajo manual
- ✅ **Mejora la UX** progresivamente a medida que se agregan datos

---

## 🏗️ Arquitectura

### Backend (Node.js + MongoDB)

#### 1. Modelo de Datos - `Neighborhood`
**Archivo**: `backend/models/neighborhood.js`

```javascript
{
  name: String,              // Nombre del barrio
  cityId: String,            // ID de Georef de la ciudad
  cityName: String,          // Nombre de la ciudad
  provinceName: String,      // Nombre de la provincia
  geometry: {                // Polígono GeoJSON
    type: Polygon|MultiPolygon,
    coordinates: Array
  },
  osmId: String,             // ID de OpenStreetMap
  source: 'osm'|'official'|'manual'
}
```

**Índices**:
- `2dsphere` en `geometry` → búsquedas geoespaciales
- Compuesto en `cityId + name` → búsquedas rápidas

#### 2. API Endpoint
**Ruta**: `GET /api/neighborhoods`

**Parámetros**:
- `cityId` (requerido): ID de Georef de la ciudad
- `search` (opcional): Filtro de texto para búsqueda

**Respuesta**:
```json
{
  "count": 48,
  "data": [
    {
      "_id": "...",
      "name": "Almagro",
      "cityName": "Ciudad Autónoma de Buenos Aires",
      "provinceName": "Ciudad Autónoma de Buenos Aires"
    }
  ]
}
```

**Endpoint adicional**: `GET /api/neighborhoods/stats`
- Muestra estadísticas de barrios cargados por ciudad

---

### Frontend (Flutter)

#### Lógica Híbrida en `housing_info_page.dart`

**Flujo de Trabajo**:

1. Usuario selecciona **Provincia** (API Georef)
2. App carga **Ciudades** de esa provincia (API Georef)
3. Para cada ciudad, consulta `GET /api/neighborhoods?cityId=X`
4. **Decisión automática**:
   - ✅ Si hay barrios → Muestra **Dropdown/TypeAhead**
   - ❌ Si no hay barrios → Muestra **TextField libre**

**Código clave** (líneas ~447-530):
```dart
// Verificar si hay barrios reales o solo ciudades
final hasRealNeighborhoods = neighborhoods.any((n) => n['hasData'] == true);

if (hasRealNeighborhoods) {
  // Mostrar FilterChip con barrios
} else {
  // Mostrar TextField libre
}
```

**Campos agregados**:
```dart
List<Map<String, dynamic>> neighborhoodsOrigin = [];
List<Map<String, dynamic>> neighborhoodsDestination = [];
String? selectedOriginCityId;
String? selectedDestinationCityId;
```

---

## 🗺️ Obtención de Datos - OpenStreetMap

### Método 1: Overpass Turbo (Recomendado para iniciar)

#### Paso 1: Ir a [Overpass Turbo](https://overpass-turbo.eu/)

#### Paso 2: Query para Córdoba
```overpass
[out:json][timeout:60];
{{geocodeArea:Córdoba, Argentina}}->.searchArea;
(
  way["boundary"="neighbourhood"](area.searchArea);
  relation["boundary"="neighbourhood"](area.searchArea);
  way["place"="neighbourhood"](area.searchArea);
  relation["place"="neighbourhood"](area.searchArea);
);
out body;
>;
out skel qt;
```

**Para otras ciudades**: Cambia `Córdoba, Argentina` por:
- `Ciudad Autónoma de Buenos Aires, Argentina`
- `Rosario, Santa Fe, Argentina`
- `Mendoza, Argentina`

#### Paso 3: Ejecutar y descargar como GeoJSON
Botón **"Export"** → **"download/copy as GeoJSON"**

#### Paso 4: Guardar como `neighborhoods_data.json`

---

### Método 2: Script de Importación Automática

**Archivo**: `backend/importNeighborhoods.js`

#### Configuración Inicial
Editar líneas 35-39:
```javascript
const CITY_CONFIG = {
  cityName: 'Córdoba',
  provinceName: 'Córdoba',
  cityId: '14014010000' // Obtener desde API Georef
};
```

**Obtener cityId de Georef**:
```bash
curl "https://apis.datos.gob.ar/georef/api/localidades?nombre=Córdoba&max=1"
```

#### Uso del Script

**Opción A: Importar desde archivo GeoJSON local**
```bash
cd backend
node importNeighborhoods.js neighborhoods_data.json
```

**Opción B: Consultar directamente Overpass API** (más lento)
```bash
node importNeighborhoods.js --api "Córdoba"
```

**Ver ayuda completa**:
```bash
node importNeighborhoods.js --help
```

#### Salida esperada:
```
✓ Conectado a MongoDB
📂 Archivo cargado: 250 features encontradas
✓ Importado: Alberdi
✓ Importado: Alta Córdoba
✓ Importado: Arguello
...
📊 Resumen de importación:
   ✓ Importados: 247
   ⏭️  Saltados: 3
   ❌ Errores: 0

📈 Total de barrios en Córdoba: 247
✓ Desconectado de MongoDB
```

---

## 📦 Plan de Implementación Piloto

### Fase 1: Córdoba Capital (Ahora) ✅
```bash
# 1. Descargar datos de Overpass Turbo
# 2. Configurar script con cityId de Córdoba
# 3. Importar
cd backend
node importNeighborhoods.js neighborhoods_data.json

# 4. Verificar
curl "http://localhost:3000/api/neighborhoods?cityId=14014010000" | jq '.count'
# Debe mostrar: ~250
```

### Fase 2: CABA (Siguiente)
```bash
# Obtener ID de CABA
curl "https://apis.datos.gob.ar/georef/api/localidades?nombre=Buenos%20Aires&max=1"

# Actualizar CITY_CONFIG con:
# cityId: '02000010000' (ejemplo, verificar)
# cityName: 'Ciudad Autónoma de Buenos Aires'
# provinceName: 'Ciudad Autónoma de Buenos Aires'

# Importar
node importNeighborhoods.js --api "Ciudad Autónoma de Buenos Aires"
```

### Fase 3: Escalado Masivo (Opcional)
Query para **TODO el país** (tarda ~5 minutos):
```overpass
[out:json][timeout:300];
{{geocodeArea:Argentina}}->.searchArea;
(
  way["boundary"="neighbourhood"](area.searchArea);
  relation["boundary"="neighbourhood"](area.searchArea);
  way["place"="neighbourhood"](area.searchArea);
  relation["place"="neighbourhood"](area.searchArea);
);
out body;
>;
out skel qt;
```

⚠️ **Advertencia**: Esto descarga miles de barrios. Revisar límites de Overpass API.

---

## 🔄 Flujo de Usuario Final

### Escenario A: Usuario en Córdoba (con datos)
1. Selecciona "Córdoba" en provincia
2. Ve 247 barrios en chips interactivos
3. Busca "Nueva" → aparece "Nueva Córdoba"
4. Selecciona hasta 5 barrios
5. ✅ **Datos normalizados** → matching preciso

### Escenario B: Usuario en pueblo pequeño (sin datos)
1. Selecciona "La Pampa" en provincia
2. Ve campo de texto libre
3. Escribe "Centro, Barrio Norte" y presiona Enter
4. ✅ **Funcionalidad completa** → no bloqueado

---

## 🎯 Ventajas de este Enfoque

| Ventaja | Descripción |
|---------|-------------|
| **Escalable** | Agregar datos no requiere cambios de código |
| **Progresivo** | UX mejora automáticamente al agregar ciudades |
| **Sin bloqueos** | Usuarios de ciudades pequeñas pueden usar la app |
| **SEO-friendly** | URLs como `/cordoba/nueva-cordoba` posibles |
| **Matching mejorado** | Algoritmo puede usar distancias reales entre barrios |
| **Mantenible** | OpenStreetMap se actualiza por la comunidad |

---

## 📊 Monitoreo

### Ver estadísticas de barrios cargados
```bash
curl http://localhost:3000/api/neighborhoods/stats
```

**Respuesta**:
```json
{
  "totalCities": 2,
  "cities": [
    {
      "cityId": "14014010000",
      "cityName": "Córdoba",
      "provinceName": "Córdoba",
      "neighborhoodsCount": 247
    },
    {
      "cityId": "02000010000",
      "cityName": "Ciudad Autónoma de Buenos Aires",
      "provinceName": "Ciudad Autónoma de Buenos Aires",
      "neighborhoodsCount": 48
    }
  ]
}
```

---

## 🛠️ Mantenimiento

### Actualizar barrios de una ciudad
```bash
# 1. Descargar nuevo GeoJSON de Overpass Turbo
# 2. El script detecta duplicados (por nombre + cityId)
# 3. Solo importa los nuevos
node importNeighborhoods.js new_neighborhoods.json
```

### Limpiar barrios de una ciudad (si es necesario)
```javascript
// En MongoDB shell o mediante endpoint
db.neighborhoods.deleteMany({ cityId: '14014010000' });
```

---

## 🚀 Próximos Pasos

1. **Ahora**: Importar barrios de Córdoba para piloto
2. **Esta semana**: Importar CABA y Rosario
3. **Siguiente sprint**: Agregar 10 ciudades más importantes
4. **Futuro**: Considerar importación masiva de todo el país

---

## 📝 Notas Técnicas

- **Tiempo de carga**: ~2-3 segundos por ciudad (consulta a backend)
- **Tamaño de DB**: ~1KB por barrio → 250 barrios = 250KB
- **Caché**: Considerar cache de 24hs en cliente para provincias/ciudades frecuentes
- **Límite Overpass**: Máx 25MB de respuesta, ~10k elementos
- **Alternativas a OSM**: 
  - datos.gob.ar (CABA tiene dataset oficial)
  - Municipalidades locales (Córdoba Capital publica GeoJSON)

---

## 🔗 Enlaces Útiles

- [Overpass Turbo](https://overpass-turbo.eu/)
- [API Georef](https://apis.datos.gob.ar/georef/)
- [Portal de Datos Abiertos Argentina](https://datos.gob.ar/)
- [OSM Wiki - Argentina](https://wiki.openstreetmap.org/wiki/Argentina)
