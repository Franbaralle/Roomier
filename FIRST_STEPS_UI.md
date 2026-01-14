# UI de First Steps - FREE vs PREMIUM

## 📱 Implementación en Flutter

### Cambios realizados (10 ene 2026)

#### 1. Variables agregadas en `home.dart`
```dart
int _firstStepsRemaining = 5;
bool _isPremium = false;
bool _resetsWeekly = false;  // ⭐ NUEVO
```

#### 2. Servicio actualizado (`chat_service.dart`)
```dart
return {
  'firstStepsRemaining': data['firstStepsRemaining'] ?? 5,
  'isPremium': data['isPremium'] ?? false,
  'resetsWeekly': data['resetsWeekly'] ?? false  // ⭐ NUEVO
};
```

---

## 🎨 Experiencia de Usuario

### Contador de First Steps (ícono flotante)

**Texto del SnackBar:**
- 💜 **PREMIUM**: "X de 5 esta semana"
- 🆓 **FREE**: "X de 5 totales (FREE)"

---

### Popup cuando se agotan (0 First Steps)

#### Usuarios FREE 🆓
```
┌─────────────────────────────────┐
│ ⭐ Sin primeros pasos           │
├─────────────────────────────────┤
│ ¡Te quedaste sin primeros       │
│ pasos!                          │
│                                 │
│ Suscribite a Premium y conseguí:│
│ 🔄 5 primeros pasos RENOVABLES  │
│    cada semana                  │
│ 👁 Ver quién te dio like        │
│ ⭐ Ver reviews completas         │
│                                 │
│ ┌───────────────────────────┐   │
│ │ 💡 FREE: Solo 5 TOTALES   │   │
│ │ 💎 PREMIUM: 5/semana      │   │
│ └───────────────────────────┘   │
├─────────────────────────────────┤
│ [Ahora no]    [Suscribirme] 💛  │
└─────────────────────────────────┘
```

#### Usuarios PREMIUM 💎
```
┌─────────────────────────────────┐
│ ⭐ Esperá una semana             │
├─────────────────────────────────┤
│ ¡Ya usaste tus 5 First Steps    │
│ de esta semana!                 │
│                                 │
│ Como usuario Premium, tus First │
│ Steps se renuevan automáticamente│
│ cada 7 días.                    │
│                                 │
│ ┌───────────────────────────┐   │
│ │ ⏰ Volvé la próxima semana│   │
│ │    para más               │   │
│ └───────────────────────────┘   │
├─────────────────────────────────┤
│              [Entendido]        │
└─────────────────────────────────┘
```

---

## 🔄 Flujo de Usuario

### Usuario FREE
1. ✅ Comienza con 5 First Steps
2. 👆 Desliza hacia arriba → usa 1 First Step
3. 🔢 Contador baja: 5 → 4 → 3 → 2 → 1 → 0
4. 🚫 Al llegar a 0: Popup "Suscribite a Premium"
5. ❌ **NUNCA resetea** (permanece en 0)

### Usuario PREMIUM
1. ✅ Comienza con 5 First Steps
2. 👆 Desliza hacia arriba → usa 1 First Step
3. 🔢 Contador baja: 5 → 4 → 3 → 2 → 1 → 0
4. ⏰ Al llegar a 0: Popup "Esperá una semana"
5. 🔄 **Después de 7 días**: Resetea automáticamente a 5

---

## 💡 Mensajes claros

### Diferenciación visual

**SnackBar (al tocar ícono ⬆️):**
- FREE: `"X de 5 totales (FREE)"` ← Enfatiza que son limitados
- PREMIUM: `"X de 5 esta semana"` ← Enfatiza la renovación

**Popup (sin First Steps):**
- FREE: Botón "Suscribirme" → Call to action claro
- PREMIUM: Solo "Entendido" → No hay venta, solo info

---

## ✅ Ventajas de esta implementación

### Para conversión a Premium:
1. 🎯 **Incentivo visual claro**: "(FREE)" en el contador
2. 💰 **Diferencia explícita**: "5 totales vs 5/semana"
3. 🚀 **Momento perfecto**: Popup justo cuando se agotan
4. ✨ **Propuesta de valor**: "RENOVABLES" destacado

### Para UX:
1. ✅ **Transparente**: Usuario sabe exactamente qué tiene
2. 🔢 **Predecible**: Contador visible todo el tiempo
3. 📝 **Educativo**: Popup explica la diferencia
4. 🎨 **Consistente**: Mismo estilo en toda la app

---

## 🧪 Testing recomendado

### Casos de prueba:

1. **Usuario FREE nuevo**:
   - ✅ Debe ver "5 de 5 totales (FREE)"
   - ✅ Usar 1 First Step → "4 de 5 totales (FREE)"
   - ✅ Usar 5 → Popup con botón "Suscribirme"

2. **Usuario PREMIUM nuevo**:
   - ✅ Debe ver "5 de 5 esta semana"
   - ✅ Usar 5 → Popup "Esperá una semana"
   - ✅ Después de 7 días → Resetea a "5 de 5 esta semana"

3. **Transición FREE → PREMIUM**:
   - ✅ FREE con 0 pasos → se suscribe → debe resetear a 5
   - ✅ Texto cambia de "(FREE)" a "esta semana"

---

**Implementado por**: GitHub Copilot  
**Fecha**: 10 de Enero 2026  
**Archivos modificados**:
- `lib/home.dart` (3 cambios)
- `lib/chat_service.dart` (1 cambio)
- `backend/routes/chat.js` (2 cambios)
