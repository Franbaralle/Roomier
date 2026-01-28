# 📝 Guía: Actualizar Datos en Producción

## Problema
Los barrios de Villa Carlos Paz están solo en tu MongoDB local. La app en producción (Render) no los ve porque están en diferentes bases de datos.

## ✅ Solución Recomendada: Ejecutar script contra MongoDB Atlas

### Paso 1: Obtener tu MONGODB_URI de producción

Ve a Render Dashboard → Tu servicio → Environment → Copia `MONGODB_URI`

Debería verse así:
```
mongodb+srv://usuario:password@cluster.mongodb.net/nombre_db
```

### Paso 2: Ejecutar el script localmente apuntando a producción

```powershell
# En la carpeta backend/
$env:MONGODB_URI="mongodb+srv://tu-uri-completa"
node importVillaCarlosPazManual.js
```

Esto importará los 30 barrios de Villa Carlos Paz directamente a tu base de datos de producción.

---

## 🔄 Alternativa: Push a Git y ejecutar en Render

Si prefieres, puedes:

1. **Hacer commit y push de los scripts:**
```powershell
git add backend/importVillaCarlosPazManual.js
git commit -m "Add Villa Carlos Paz neighborhoods import script"
git push origin main
```

2. **Conectarte a Render y ejecutar:**
- Ve a Render Dashboard → Tu servicio
- Abre el "Shell" (botón en la interfaz)
- Ejecuta: `node importVillaCarlosPazManual.js`

---

## ✅ Verificar que funcionó

Después de importar, prueba en tu app:
1. Selecciona provincia: Córdoba
2. Escribe en ciudad: "Villa Carlos Paz" o "Carlos Paz"
3. Deberías ver los 30 barrios disponibles

---

## 🔍 Sobre la búsqueda sin acentos

Ya actualicé el código Flutter para que ignore acentos. Ahora puedes buscar:
- "Cordoba" o "Córdoba" → mismo resultado
- "Carlos Paz" o "Villa Carlos Paz" → mismo resultado

Los cambios están en `lib/housing_info_page.dart`.

---

## 📋 Checklist

- [ ] Copiar MONGODB_URI de Render
- [ ] Ejecutar `node importVillaCarlosPazManual.js` con la URI de producción
- [ ] Verificar en la app que Villa Carlos Paz aparece
- [ ] (Opcional) Hacer commit de los scripts para tenerlos en el repo
