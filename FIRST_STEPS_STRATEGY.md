# Sistema de First Steps - Estrategia Freemium

**Fecha de implementación**: 8-10 de Enero 2026

## 🎯 Estrategia

### Usuarios FREE
- ✅ **5 First Steps TOTALES** (lifetime)
- ❌ **NO resetean** nunca
- ⚠️ Cuando se acaban, se acabaron
- 💡 **Incentivo fuerte** para upgrade a Premium

### Usuarios PREMIUM  
- ✅ **5 First Steps POR SEMANA**
- 🔄 **Reseteo automático** cada 7 días
- 📅 Control de `firstStepsResetDate`
- ♾️ Uso **renovable** indefinidamente

---

## 🔧 Implementación Técnica

### Modelo de Usuario (User.js)
```javascript
{
  firstStepsRemaining: Number (default: 5, min: 0),
  isPremium: Boolean (default: false),
  firstStepsUsedThisWeek: Number (default: 0),
  firstStepsResetDate: Date (default: now)
}
```

### Lógica de Reseteo (chat.js)

**Cuándo se verifica:**
- Al crear un First Step (`POST /api/chat/create_chat`)
- Al consultar pasos disponibles (`GET /api/chat/first_steps_remaining/:username`)

**Cómo funciona:**
```javascript
if (user.isPremium) {
  const daysSinceReset = (now - lastReset) / (1000 * 60 * 60 * 24);
  
  if (daysSinceReset >= 7) {
    user.firstStepsRemaining = 5;
    user.firstStepsUsedThisWeek = 0;
    user.firstStepsResetDate = now;
    await user.save();
  }
}
```

**Validación:**
- FREE sin pasos → `"Upgrade to Premium for weekly reset"`
- PREMIUM sin pasos → `"No first steps remaining this week"`

---

## 💰 Beneficios Premium Totales

1. 🔄 **First Steps renovables** (5/semana vs 5 totales)
2. ⭐ **Ver reviews completas** (usuarios que buscan lugar)
3. 👀 **Ver likes recibidos** sin blur
4. 💬 **Enviar mensajes** en First Steps (1 inicial)

---

## 📊 Ventajas de esta Estrategia

### Para el negocio:
✅ **Incentivo claro** para conversión a Premium  
✅ **Valor percibido alto** (renovación vs agotamiento)  
✅ **Uso estratégico** de First Steps (no spam)  
✅ **Equilibrio** entre freemium y premium

### Para los usuarios:
✅ **FREE viable** para usuarios casuales (5 intentos)  
✅ **PREMIUM justo** para usuarios activos (renovación)  
✅ **Transparencia** en límites  
✅ **Validación social** con reviews

---

## 🚀 Próximos Pasos

1. ✅ **Backend implementado** con lógica de reseteo
2. ⚠️ **Frontend**: Actualizar UI para mostrar diferencia FREE/PREMIUM
3. ⚠️ **Testing**: Probar con usuarios de ambos tipos
4. ⚠️ **Monetización**: Integrar Stripe/MercadoPago

---

## 📝 Notas Importantes

- El reseteo es **automático** (no requiere cron jobs)
- Se verifica en **cada uso** (lazy evaluation)
- **Mensajes claros** según tipo de usuario
- Campo `resetsWeekly` en respuesta API para UI

---

**Documentado por**: GitHub Copilot  
**Última actualización**: 10 de Enero 2026
