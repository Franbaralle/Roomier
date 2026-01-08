# 📚 Scripts de Migración de Usuarios

## Descripción

Scripts para mantener la base de datos de usuarios actualizada y normalizada.

---

## 1. `addFirstStepsToUsers.js`

### ¿Qué hace?
Agrega los campos necesarios para el sistema de "Primeros Pasos" a todos los usuarios existentes.

### Campos agregados:
- `firstStepsRemaining: 5` - Contador de primeros pasos disponibles
- `firstStepsUsedThisWeek: 0` - Contador semanal de uso
- `firstStepsResetDate: Date.now()` - Fecha de último reset
- `isPremium: false` - Estado premium del usuario

### Cuándo usarlo:
- Después de implementar la feature de "Primeros Pasos"
- Cuando usuarios existentes necesiten acceder a la funcionalidad
- Antes de hacer pruebas con usuarios ya creados

### Cómo ejecutar:
```bash
# Desde la raíz del proyecto
node backend/scripts/addFirstStepsToUsers.js
```

### Output esperado:
```
✅ Conectado a MongoDB
📊 Usuarios sin campo firstStepsRemaining: 8
✅ Actualización completada:
   - Usuarios encontrados: 8
   - Usuarios modificados: 8

📋 Ejemplo de usuarios actualizados:
   - FranBara: 5 pasos, Premium: false
   - Prueba3: 5 pasos, Premium: false
   - Prueba4: 5 pasos, Premium: false

✅ Migración completada exitosamente
```

---

## 2. `normalizeUserData.js`

### ¿Qué hace?
Normaliza la estructura de datos de todos los usuarios para mantener consistencia.

### Operaciones:
1. **Elimina campos obsoletos:**
   - `profilePhotoBuffer` (se migró a Cloudinary)
   - `profilePhotoPublicId` (campo innecesario)

2. **Agrega campos faltantes:**
   - `personalInfo` (aboutMe, job, politicPreference, religion)
   - `roommatePreferences` (gender, ageMin, ageMax)
   - `profilePhotos` (array)
   - `homePhotos` (array)
   - `legacyPreferences` (array)
   - `dealBreakers` (objeto completo)
   - `verification` (objeto completo)

3. **Valida estructuras:**
   - Asegura que `preferences` tenga todas las categorías
   - Verifica campos críticos (foto de perfil, género)

### Cuándo usarlo:
- Después de cambios en el schema del modelo User
- Cuando hay inconsistencias entre usuarios viejos y nuevos
- Antes de hacer testing exhaustivo
- Periódicamente para mantener limpia la DB

### Cómo ejecutar:
```bash
# Desde la raíz del proyecto
node backend/scripts/normalizeUserData.js
```

### Output esperado:
```
✅ Conectado a MongoDB
📊 Total de usuarios a normalizar: 8

🗑️  FranBara: Eliminando profilePhotoBuffer
🗑️  FranBara: Eliminando profilePhotoPublicId
➕ Prueba4: Agregando personalInfo
➕ Prueba3: Agregando roommatePreferences

✅ Normalización completada:
   - Usuarios procesados: 8
   - Usuarios actualizados: 5

⚠️  Problemas detectados (requieren atención manual):
   ⚠️  TestUser5: Sin foto de perfil
   ⚠️  TestUser6: Sin género definido

📋 Ejemplo de usuarios normalizados:
   Usuario: FranBara
   - personalInfo: ✅
   - roommatePreferences: ✅
   - profilePhotos: ✅
   - homePhotos: ✅

✅ Script completado exitosamente
```

---

## 3. Orden de ejecución recomendado

Para actualizar usuarios existentes después de cambios importantes:

```bash
# 1. Primero normalizar datos
node backend/scripts/normalizeUserData.js

# 2. Luego agregar campos de primeros pasos
node backend/scripts/addFirstStepsToUsers.js
```

---

## 🔒 Seguridad

- ✅ Los scripts usan la misma conexión a MongoDB que la app
- ✅ Requieren la variable `MONGODB_URI` en `.env`
- ✅ No eliminan datos importantes, solo campos obsoletos
- ✅ Son idempotentes (se pueden ejecutar múltiples veces sin problemas)

---

## 🧪 Testing

Antes de ejecutar en producción:

1. **Respaldar base de datos:**
   ```bash
   # Crear backup de MongoDB Atlas
   # Desde el dashboard de Atlas > Backup
   ```

2. **Ejecutar en ambiente de desarrollo primero:**
   ```bash
   # Cambiar temporalmente MONGODB_URI a DB de prueba
   node backend/scripts/normalizeUserData.js
   ```

3. **Verificar resultados:**
   - Revisar logs del script
   - Verificar algunos usuarios manualmente en MongoDB Compass
   - Probar login y funcionalidades básicas

4. **Ejecutar en producción:**
   - Cambiar `MONGODB_URI` a producción
   - Ejecutar scripts
   - Monitorear errores en Railway

---

## 📝 Logs

Los scripts generan logs detallados:
- ✅ Operaciones exitosas
- ➕ Campos agregados
- 🗑️ Campos eliminados
- ⚠️ Problemas detectados
- ❌ Errores

---

## 🐛 Troubleshooting

### Error: "Cannot connect to MongoDB"
```bash
# Verificar que .env tiene MONGODB_URI
cat .env | grep MONGODB_URI

# Verificar conexión
node -e "console.log(process.env.MONGODB_URI)"
```

### Error: "User is not defined"
```bash
# Asegurarse de ejecutar desde la raíz del proyecto
cd backend
node scripts/normalizeUserData.js  # ❌

cd ..  # Volver a raíz
node backend/scripts/normalizeUserData.js  # ✅
```

### Script se queda colgado
- Verificar que no hay procesos de Node ejecutándose
- Cerrar MongoDB Compass u otras conexiones
- Reiniciar la terminal

---

## 📊 Estadísticas

Usuarios afectados por normalización (ejemplo):
- Total: 8 usuarios
- Con `profilePhotoBuffer` obsoleto: 3 usuarios
- Sin `personalInfo`: 2 usuarios  
- Sin `roommatePreferences`: 1 usuario
- Sin campos de primeros pasos: 8 usuarios

---

**Última actualización:** 8 de Enero de 2026
**Autor:** Sistema de migración Roomier
