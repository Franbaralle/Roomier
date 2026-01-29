# 📍 Sistema de Sugerencias de Barrios

## Problema Resuelto

Cuando los usuarios seleccionan ciudades para las cuales no tenemos barrios cargados en la base de datos (como Misiones), ahora pueden **sugerir hasta 5 barrios** que conocen. Este sistema ayuda a:

1. ✅ Permitir que los usuarios completen su registro sin bloqueos
2. ✅ Recopilar información valiosa sobre qué barrios agregar
3. ✅ Identificar ciudades prioritarias para expandir la cobertura
4. ✅ Mantener control sobre la calidad de los datos

---

## 🎨 Interfaz de Usuario

### Cuando HAY barrios en la BD
- Se muestra un campo de búsqueda
- Chips clickeables para seleccionar barrios
- Máximo 5 barrios seleccionables

### Cuando NO HAY barrios en la BD
- Banner informativo naranja: "No tenemos barrios cargados para esta ciudad. Ayúdanos escribiendo los que conozcas (máx. 5)"
- Campo de texto para escribir el nombre del barrio
- Botón **+** para agregar el barrio
- El campo se deshabilita al llegar a 5 barrios
- Mensaje de confirmación: "✓ Has alcanzado el límite de 5 barrios"

### Experiencia del Usuario
```
[Campo de texto: "Ej: Centro, Barrio Norte..."] [Botón +]

Seleccionados:
[Centro ×] [Barrio Norte ×] [Villa Nueva ×]
```

---

## 🔧 Implementación Técnica

### Frontend (Flutter)

**Archivos modificados:**
- `lib/housing_info_page.dart`

**Nuevos controladores:**
```dart
final TextEditingController freeNeighborhoodOriginController = TextEditingController();
final TextEditingController freeNeighborhoodDestinationController = TextEditingController();
```

**Lógica de envío:**
- Al hacer clic en "Continuar", se verifica si hay barrios sugeridos
- Solo se envían si `neighborhoodsOrigin` o `neighborhoodsDestination` están vacíos (sin data en BD)
- El envío NO bloquea el registro (si falla, solo se loguea el error)

### Backend (Node.js)

**Archivos nuevos:**
- `backend/models/suggestedNeighborhood.js` - Modelo de MongoDB
- Endpoint agregado en `backend/routes/neighborhoods.js`

**Modelo de datos:**
```javascript
{
  name: String,              // Nombre del barrio
  cityId: String,            // ID de Georef
  cityName: String,
  provinceName: String,
  userId: ObjectId,          // Opcional
  userEmail: String,
  suggestionCount: Number,   // Contador de sugerencias
  suggestedBy: [{            // Array de usuarios que lo sugirieron
    userId: ObjectId,
    email: String,
    date: Date
  }],
  status: String,            // 'pending', 'approved', 'rejected', 'duplicate'
  adminNotes: String,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 📡 Endpoints del API

### 1. Enviar Sugerencias (usado por la app)

```bash
POST /api/neighborhoods/suggest
```

**Body:**
```json
{
  "neighborhoods": ["Centro", "Barrio Norte", "Villa Nueva"],
  "cityId": "70028",
  "cityName": "Posadas",
  "provinceName": "Misiones",
  "userEmail": "usuario@ejemplo.com",
  "userId": "optional-user-id"
}
```

**Respuesta exitosa:**
```json
{
  "success": true,
  "saved": 3,
  "message": "3 barrios procesados correctamente"
}
```

**Características:**
- ✅ Evita duplicados (case insensitive)
- ✅ Incrementa contador si el barrio ya fue sugerido
- ✅ Registra qué usuarios sugirieron cada barrio
- ✅ No falla si un usuario sugiere el mismo barrio dos veces

---

### 2. Consultar Sugerencias (para administradores)

```bash
GET /api/neighborhoods/suggestions
```

**Query params opcionales:**
- `cityId` - Filtrar por ciudad específica
- `status` - Filtrar por estado (`pending`, `approved`, `rejected`)
- `minCount` - Mínimo de sugerencias (ej: `?minCount=3` para ver solo los más sugeridos)

**Ejemplo de consulta:**
```bash
# Ver todas las sugerencias pendientes
curl https://roomier-qeyu.onrender.com/api/neighborhoods/suggestions?status=pending

# Ver sugerencias para Posadas
curl https://roomier-qeyu.onrender.com/api/neighborhoods/suggestions?cityId=70028

# Ver solo barrios sugeridos 3+ veces
curl https://roomier-qeyu.onrender.com/api/neighborhoods/suggestions?minCount=3
```

**Respuesta:**
```json
{
  "total": 15,
  "byCityCount": 3,
  "byCity": [
    {
      "cityId": "70028",
      "cityName": "Posadas",
      "provinceName": "Misiones",
      "suggestions": [
        {
          "name": "Centro",
          "count": 5,
          "status": "pending",
          "createdAt": "2026-01-29T..."
        },
        {
          "name": "Barrio Norte",
          "count": 3,
          "status": "pending",
          "createdAt": "2026-01-29T..."
        }
      ]
    }
  ]
}
```

---

## 🔍 Cómo Revisar las Sugerencias

### Opción 1: Desde MongoDB Compass

```javascript
// Ver todas las sugerencias ordenadas por contador
db.suggestedneighborhoods.find({}).sort({ suggestionCount: -1 })

// Ver sugerencias para una ciudad específica
db.suggestedneighborhoods.find({ 
  cityName: "Posadas" 
}).sort({ suggestionCount: -1 })

// Ver solo las pendientes con 3+ sugerencias
db.suggestedneighborhoods.find({ 
  status: "pending",
  suggestionCount: { $gte: 3 }
})
```

### Opción 2: Desde el API (Postman/cURL)

```bash
# Listar sugerencias más populares
curl https://roomier-qeyu.onrender.com/api/neighborhoods/suggestions?minCount=2

# Filtrar por ciudad
curl https://roomier-qeyu.onrender.com/api/neighborhoods/suggestions?cityName=Posadas
```

---

## 📊 Flujo de Trabajo para Administradores

### 1. **Revisar sugerencias periódicamente**
```bash
# Cada semana/mes, revisar qué barrios se han sugerido
GET /api/neighborhoods/suggestions?status=pending&minCount=2
```

### 2. **Analizar los más populares**
- Barrios con `suggestionCount >= 3` son buenos candidatos
- Ver qué ciudades tienen más sugerencias
- Priorizar ciudades con beta testers activos

### 3. **Agregar barrios a la BD**

Si decides agregar un barrio sugerido:

```javascript
// Opción A: Usar el script existente
// Modifica importNeighborhoods.js para incluir la nueva ciudad

// Opción B: Crear directamente en MongoDB
db.neighborhoods.insertOne({
  name: "Centro",
  cityId: "70028",
  cityName: "Posadas",
  provinceName: "Misiones"
})
```

### 4. **Marcar como aprobado**

```javascript
// Actualizar el estado en suggestedneighborhoods
db.suggestedneighborhoods.updateOne(
  { name: "Centro", cityId: "70028" },
  { 
    $set: { 
      status: "approved",
      adminNotes: "Agregado a la BD el 29/01/2026"
    }
  }
)
```

### 5. **Rechazar duplicados o incorrectos**

```javascript
db.suggestedneighborhoods.updateOne(
  { name: "BarrioInventado", cityId: "70028" },
  { 
    $set: { 
      status: "rejected",
      adminNotes: "Barrio no existe"
    }
  }
)
```

---

## 🚀 Casos de Uso

### Caso 1: Beta Tester de Misiones
1. Usuario se registra y selecciona "Posadas, Misiones"
2. No hay barrios en la BD → ve el campo libre
3. Escribe: "Centro", "Barrio Itaembé Miní", "Villa Urquiza"
4. Hace clic en "Continuar"
5. Los 3 barrios se envían al backend automáticamente
6. El registro continúa normalmente

### Caso 2: Análisis después de 1 mes
```bash
# Ver qué ciudades necesitan cobertura urgente
GET /api/neighborhoods/suggestions
```

Resultado:
- **Posadas**: 15 sugerencias (5 usuarios)
- **Oberá**: 8 sugerencias (3 usuarios)
- **Eldorado**: 3 sugerencias (1 usuario)

**Decisión:** Agregar barrios de Posadas y Oberá primero.

---

## ⚠️ Consideraciones Importantes

### Validación de Datos
- ❌ No hay validación automática de si el barrio existe realmente
- ⚠️ Los usuarios pueden escribir cualquier cosa
- ✅ El contador de sugerencias ayuda a filtrar datos confiables

### Recomendaciones
1. **No agregar automáticamente** a la BD
2. **Revisar manualmente** antes de aprobar
3. **Priorizar barrios con 3+ sugerencias**
4. **Usar Google Maps** para verificar que existan
5. **Consultar con el beta tester** si tienes dudas

### Limpieza de Datos
```javascript
// Eliminar sugerencias spam o inválidas
db.suggestedneighborhoods.deleteMany({ 
  status: "rejected",
  createdAt: { $lt: new Date("2026-01-01") }
})
```

---

## 📈 Métricas Sugeridas

### Queries útiles para análisis:

```javascript
// Top 10 barrios más sugeridos
db.suggestedneighborhoods.aggregate([
  { $match: { status: "pending" } },
  { $sort: { suggestionCount: -1 } },
  { $limit: 10 }
])

// Ciudades con más sugerencias
db.suggestedneighborhoods.aggregate([
  { $group: {
    _id: "$cityName",
    totalSuggestions: { $sum: "$suggestionCount" },
    uniqueNeighborhoods: { $sum: 1 }
  }},
  { $sort: { totalSuggestions: -1 } }
])

// Actividad por fecha
db.suggestedneighborhoods.aggregate([
  { $group: {
    _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
    count: { $sum: 1 }
  }},
  { $sort: { _id: -1 } }
])
```

---

## 🎯 Próximos Pasos

1. ✅ **Sistema implementado y funcional**
2. ⏳ Esperar 1-2 semanas de recolección de datos
3. ⏳ Revisar sugerencias con `GET /api/neighborhoods/suggestions?minCount=2`
4. ⏳ Agregar barrios más populares a la BD
5. ⏳ Notificar a los usuarios cuando sus sugerencias sean aprobadas (futuro)

---

## 🔗 Archivos Relacionados

- Frontend: [housing_info_page.dart](../lib/housing_info_page.dart)
- Backend modelo: [suggestedNeighborhood.js](./models/suggestedNeighborhood.js)
- Backend rutas: [neighborhoods.js](./routes/neighborhoods.js)
- Documentación barrios: [NEIGHBORHOODS_HYBRID_SYSTEM.md](../NEIGHBORHOODS_HYBRID_SYSTEM.md)

---

**Creado:** 29 de Enero 2026  
**Versión:** 1.0  
**Estado:** ✅ Implementado y funcional
