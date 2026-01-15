# Scripts de Migración - Sistema de Ubicación

Este directorio contiene scripts para migrar los datos de ubicación de usuarios existentes al nuevo sistema con API Georef.

## 📋 Contexto

La app ahora usa:
- `originProvince` y `destinationProvince` en lugar de `city`
- `specificNeighborhoodsOrigin` y `specificNeighborhoodsDestination` en lugar de `preferredZones`
- Se eliminó `generalZone`

## 🔧 Opciones de Migración

### Opción 1: Migrar Usuarios Existentes (Recomendado)

Este script migra los datos antiguos a los nuevos campos:

```bash
cd backend
node migrateLocationFields.js
```

**Qué hace:**
- ✅ Migra `city` → `originProvince` o `destinationProvince` (según `hasPlace`)
- ✅ Migra `preferredZones` → `specificNeighborhoodsOrigin` o `specificNeighborhoodsDestination`
- ✅ Mantiene los campos legacy para compatibilidad
- ✅ No elimina datos existentes
- ⚠️ Los usuarios deberán completar campos faltantes al editar su perfil

**Ventajas:**
- No pierdes usuarios existentes
- Migración gradual
- Compatibilidad con versiones antiguas

**Desventajas:**
- Algunos campos pueden quedar incompletos
- Los usuarios tendrán que actualizar su perfil

---

### Opción 2: Limpiar Base de Datos (Empezar de Cero)

⚠️ **ADVERTENCIA: Esta opción ELIMINA TODOS los usuarios y chats**

```bash
cd backend
node clearAllUsers.js
```

**Qué hace:**
- 🗑️ Elimina TODOS los usuarios
- 🗑️ Elimina TODOS los chats
- ✅ Te permite empezar con una base limpia
- ⏳ Da 5 segundos para cancelar (Ctrl+C)

**Cuándo usar:**
- Fase de desarrollo/testing
- Antes de lanzamiento a producción
- Cuando prefieres que todos los usuarios empiecen con la estructura nueva

---

## 🚀 Recomendación

### Para Desarrollo/Testing:
```bash
node clearAllUsers.js
```
Empezar de cero es más limpio.

### Para Producción (con usuarios reales):
```bash
node migrateLocationFields.js
```
Conservar los usuarios existentes y migrar sus datos.

---

## 📊 Después de la Migración

Independientemente de la opción elegida:

1. **Construir nueva APK:**
   ```bash
   flutter build apk --release
   ```

2. **Los nuevos usuarios tendrán:**
   - Selector de provincias con API Georef
   - Búsqueda de barrios por provincia
   - DatePicker de mes para mudanza

3. **Los usuarios migrados (Opción 1):**
   - Verán sus datos antiguos en los nuevos campos
   - Deberán completar información faltante al editar perfil
   - Los campos legacy se mantienen por compatibilidad

---

## 🔍 Verificar Migración

Para verificar que la migración funcionó:

```javascript
// En MongoDB Compass o shell
db.users.findOne({}, {housingInfo: 1})
```

Deberías ver:
```json
{
  "housingInfo": {
    "originProvince": "Buenos Aires",
    "destinationProvince": "Buenos Aires",
    "specificNeighborhoodsOrigin": ["Palermo", "Recoleta"],
    "specificNeighborhoodsDestination": [],
    // Legacy fields (se mantienen)
    "city": "Buenos Aires",
    "preferredZones": ["Palermo", "Recoleta"]
  }
}
```

---

## ⚠️ Notas Importantes

- Los scripts requieren conexión a MongoDB
- Asegúrate de tener el `.env` configurado correctamente
- Los campos legacy NO se borran para mantener compatibilidad
- Se recomienda hacer backup antes de cualquier migración
- En producción, programa la migración en horario de bajo tráfico

---

## 📝 Backup Manual (Opcional)

Antes de migrar, puedes hacer backup:

```bash
mongodump --uri="mongodb://localhost:27017/roomier" --out=./backup-$(date +%Y%m%d)
```

Para restaurar:
```bash
mongorestore --uri="mongodb://localhost:27017/roomier" ./backup-20260115
```
