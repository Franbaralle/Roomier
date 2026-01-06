# Migración de Preferencias - Sistema de Tags

## Problema
Los usuarios existentes tienen `preferences` como un **array de strings** (formato antiguo), pero el nuevo sistema usa un **objeto estructurado** con categorías y subcategorías.

Cuando se intenta actualizar un usuario (por ejemplo, al subir fotos o guardar token FCM), MongoDB no puede convertir automáticamente el array a objeto, causando el error:
```
MongoServerError: Cannot create field 'convivencia' in element {preferences: [...]}
```

## Solución

### 1. Ejecutar script de migración

El script convierte todas las preferencias antiguas (array) al nuevo formato (objeto estructurado):

#### En Railway:
```bash
cd backend
npm run migrate:preferences
```

#### En desarrollo local:
```bash
cd backend
node scripts/migratePreferences.js
```

### 2. ¿Qué hace el script?

1. **Busca** todos los usuarios con `preferences` como array
2. **Convierte** el array a la estructura de objeto:
   ```javascript
   {
     convivencia: { hogar: [], social: [], mascotas: [] },
     gastronomia: { habitos: [], bebidas: [], habilidades: [] },
     deporte: { intensidad: [], menteCuerpo: [], deportesPelota: [], aguaNaturaleza: [] },
     entretenimiento: { pantalla: [], musica: [], gaming: [] },
     creatividad: { artesPlasticas: [], tecnologia: [], moda: [] },
     interesesSociales: { causas: [], conocimiento: [] }
   }
   ```
3. **Guarda** las preferencias antiguas en `legacyPreferences` por seguridad
4. **Actualiza** el usuario usando `updateOne()` para evitar validaciones

### 3. Después de la migración

- Los usuarios tendrán la estructura correcta
- Podrán subir fotos y usar todas las funciones sin errores
- **Deberán volver a seleccionar sus preferencias** usando el nuevo sistema de tags en la app

### 4. Verificar migración exitosa

Después de ejecutar el script, verás:
```
=== RESUMEN DE MIGRACIÓN ===
Total usuarios procesados: X
Migrados exitosamente: X
Errores: 0
============================
```

## Prevención futura

El modelo `user.js` ya incluye:
- Campo `legacyPreferences` para mantener compatibilidad temporal
- Estructura correcta de `preferences` como objeto

Todos los nuevos usuarios se crearán automáticamente con el formato correcto.
