# Panel de Administración - Roomier
## Documentación Técnica

### 📋 Resumen
Panel completo de administración para revisar reportes de usuarios y tomar acciones de moderación.

---

## 🎯 Funcionalidades Implementadas

### 1. Dashboard de Estadísticas
- **Reportes pendientes**: Contador destacado en naranja
- **Estadísticas por estado**: pending, reviewed, action_taken, dismissed
- **Estadísticas por razón**: Distribución de reportes por categoría
- **Top 10 usuarios más reportados**: Lista con conteo

### 2. Gestión de Reportes
**Visualización:**
- Lista completa de reportes con paginación (20 por página)
- Filtros por estado (todos, pendientes, revisados, con acción, descartados)
- Tarjetas expandibles con información completa

**Detalles mostrados:**
- Usuario reportado
- Reportado por (quien hizo el reporte)
- Razón del reporte
- Descripción adicional
- Fecha de creación
- Estado actual

**Acciones disponibles:**
- **Descartar**: Marcar reporte como no relevante
- **Tomar Acción**: Abrir diálogo para aplicar medidas

### 3. Acciones de Moderación
**Advertencia (Warning)**
- Solo se registra en logs
- No afecta la cuenta del usuario
- Útil para primeras infracciones leves

**Suspensión Temporal (Suspend)**
- Cambia `accountStatus` a 'suspended'
- Duración configurable (por defecto 7 días)
- Usuario no puede acceder durante el periodo
- Se guarda razón de suspensión

**Baneo Permanente (Ban)**
- Cambia `accountStatus` a 'banned'
- El usuario pierde acceso permanentemente
- Se guarda razón del baneo

**Eliminación de Cuenta (Delete)**
- Elimina completamente el usuario de la BD
- ⚠️ Acción irreversible

### 4. Seguridad del Panel
- **Middleware isAdmin**: Verifica que el usuario tenga flag `isAdmin: true`
- **Autenticación JWT**: Todas las rutas requieren token válido
- **Logging de acciones**: Todas las acciones admin se registran en logs
- **Protección de rutas**: 403 Forbidden si no es admin

---

## 🔌 API Endpoints

### GET `/api/admin/reports`
Obtener lista de reportes con paginación

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Query Params:**
- `status` (optional): 'all', 'pending', 'reviewed', 'action_taken', 'dismissed'
- `page` (optional): Número de página (default: 1)
- `limit` (optional): Reportes por página (default: 20)
- `sortBy` (optional): Campo para ordenar (default: 'createdAt')
- `order` (optional): 'asc' o 'desc' (default: 'desc')

**Respuesta:**
```json
{
  "reports": [
    {
      "_id": "...",
      "reportedUser": "username",
      "reportedBy": "reporter_username",
      "reason": "harassment",
      "description": "...",
      "status": "pending",
      "createdAt": "2025-12-31T..."
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 5,
    "totalReports": 95,
    "reportsPerPage": 20
  }
}
```

---

### GET `/api/admin/reports/stats`
Obtener estadísticas de reportes

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Respuesta:**
```json
{
  "statistics": {
    "byStatus": [
      { "_id": "pending", "count": 15 },
      { "_id": "reviewed", "count": 30 }
    ],
    "byReason": [
      { "_id": "harassment", "count": 25 },
      { "_id": "spam", "count": 10 }
    ],
    "topReported": [
      { "_id": "username1", "count": 5 },
      { "_id": "username2", "count": 3 }
    ],
    "recent": [
      { "pendingCount": 15 }
    ]
  },
  "generatedAt": "2025-12-31T..."
}
```

---

### GET `/api/admin/reports/:reportId`
Obtener detalles completos de un reporte

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Respuesta:**
```json
{
  "report": { ... },
  "reportedUserInfo": {
    "username": "...",
    "email": "...",
    "createdAt": "...",
    "blockedUsers": [...]
  },
  "reporterInfo": {
    "username": "...",
    "email": "...",
    "createdAt": "..."
  }
}
```

---

### PUT `/api/admin/reports/:reportId`
Actualizar estado de un reporte

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Body:**
```json
{
  "status": "reviewed",
  "actionTaken": "warning",
  "notes": "Primera advertencia"
}
```

**Respuesta:**
```json
{
  "message": "Reporte actualizado correctamente",
  "report": { ... }
}
```

---

### POST `/api/admin/users/:username/action`
Aplicar acción sobre un usuario reportado

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Body:**
```json
{
  "action": "suspend",
  "reason": "Múltiples reportes de acoso",
  "duration": 7
}
```

**Valores válidos para `action`:**
- `warning`: Solo advertencia (log)
- `suspend`: Suspensión temporal (requiere `duration` en días)
- `ban`: Baneo permanente
- `delete`: Eliminar cuenta

**Respuesta:**
```json
{
  "message": "Acción 'suspend' aplicada correctamente",
  "username": "user123",
  "action": "suspend"
}
```

---

### GET `/api/admin/users/most-reported`
Obtener usuarios con más reportes

**Headers:**
```
Authorization: Bearer <JWT_TOKEN>
```

**Query Params:**
- `limit` (optional): Número de usuarios (default: 20)

**Respuesta:**
```json
{
  "users": [
    {
      "username": "user1",
      "reportCount": 8,
      "email": "user1@example.com",
      "accountStatus": "active",
      "createdAt": "..."
    }
  ],
  "generatedAt": "2025-12-31T..."
}
```

---

## 📱 Interfaz Flutter

### Acceso al Panel
```dart
Navigator.pushNamed(context, '/admin');
```

### Tabs Disponibles
1. **Dashboard**: Resumen y estadísticas
2. **Reportes**: Lista completa con filtros
3. **Usuarios**: (Próximamente)

### Componentes Principales
- `AdminPanelPage`: Widget principal con TabController
- `_buildDashboardTab()`: Vista de estadísticas
- `_buildReportsTab()`: Lista de reportes con filtros
- `_buildReportCard()`: Tarjeta expandible de reporte
- `_showActionDialog()`: Diálogo para tomar acciones

---

## 🔐 Configuración de Admin

### Hacer a un usuario administrador

**Opción 1: MongoDB Shell**
```javascript
db.users.updateOne(
  { username: "admin_username" },
  { $set: { isAdmin: true } }
)
```

**Opción 2: Mongoose (Node.js)**
```javascript
const User = require('./models/user');

async function makeAdmin(username) {
  await User.updateOne(
    { username },
    { isAdmin: true }
  );
  console.log(`${username} is now admin`);
}

makeAdmin('admin_username');
```

---

## 📊 Modelo de Datos

### User Model (campos admin)
```javascript
{
  isAdmin: { type: Boolean, default: false },
  accountStatus: { 
    type: String, 
    enum: ['active', 'suspended', 'banned'], 
    default: 'active' 
  },
  suspendedUntil: { type: Date, required: false },
  suspensionReason: { type: String, required: false },
  banReason: { type: String, required: false }
}
```

### Report Model
```javascript
{
  reportedUser: String (required, indexed),
  reportedBy: String (required, indexed),
  reason: String (enum con 9 categorías),
  description: String (max 500),
  status: String (enum: pending, reviewed, action_taken, dismissed),
  reviewedBy: String (admin username),
  reviewDate: Date,
  actionTaken: String (enum: none, warning, temporary_ban, permanent_ban, profile_removal),
  adminNotes: String,
  createdAt: Date (default: Date.now)
}
```

---

## 🔥 Logging

Todas las acciones admin se registran en:
- **Archivo**: `backend/logs/all.log` y `backend/logs/error.log`
- **Formato**: JSON con timestamp

**Ejemplos de logs:**
```
[2025-12-31 10:30:45] info: Admin john_admin fetched 20 reports (page 1)
[2025-12-31 10:32:10] info: Admin john_admin updated report 507f1f77... to status: reviewed
[2025-12-31 10:35:22] warn: Admin john_admin suspended user baduser for 7 days
[2025-12-31 10:40:15] warn: Admin john_admin permanently banned user spammer
```

---

## 🛡️ Seguridad

### Protecciones Implementadas
1. ✅ JWT token requerido
2. ✅ Verificación de flag `isAdmin`
3. ✅ Logging de todas las acciones
4. ✅ Rate limiting en endpoints admin
5. ✅ Validación de datos en body

### Pendiente (Recomendado)
- ⚠️ 2FA para cuentas admin
- ⚠️ IP whitelist para panel admin
- ⚠️ Confirmación adicional para acciones destructivas (delete)
- ⚠️ Histórico de acciones por admin
- ⚠️ Sistema de appeals para usuarios sancionados

---

## 📝 Uso Típico

### Flujo de Moderación
1. Admin entra al panel → `/admin`
2. Ve **15 reportes pendientes** en el Dashboard
3. Va al tab "Reportes"
4. Filtra por "Pendientes"
5. Expande un reporte de acoso
6. Lee la descripción
7. Presiona "Tomar Acción"
8. Selecciona "Suspender cuenta (temporal)"
9. Agrega nota: "Primera ofensa de acoso"
10. Confirma
11. Sistema:
    - Actualiza reporte a `action_taken`
    - Suspende usuario por 7 días
    - Registra acción en logs
    - Muestra notificación de éxito

---

## 🎨 Personalización

### Cambiar duración de suspensión por defecto
En `lib/admin_panel_page.dart`:
```dart
body: json.encode({
  'action': action,
  'reason': notes.isEmpty ? 'Acción por reporte' : notes,
  'duration': action == 'suspend' ? 14 : null, // Cambiar de 7 a 14 días
}),
```

### Agregar nuevo tipo de acción
1. Actualizar enum en `backend/models/report.js`:
```javascript
actionTaken: {
  type: String,
  enum: ['none', 'warning', 'temporary_ban', 'permanent_ban', 'profile_removal', 'content_removal'], // Nuevo
  required: false
}
```

2. Agregar en `backend/routes/admin.js`:
```javascript
case 'remove_content':
  // Lógica para eliminar contenido específico
  break;
```

3. Actualizar Flutter dialog con nuevo RadioListTile

---

## 🧪 Testing

### Testear endpoints admin
Crear usuario admin de prueba:
```javascript
const User = require('./models/user');
await User.create({
  username: 'testadmin',
  password: 'hashedpassword',
  email: 'admin@test.com',
  isAdmin: true
});
```

Luego usar los tests en `backend/tests/admin.test.js` (crear si no existe)

---

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs en `backend/logs/error.log`
2. Verificar que el usuario tenga `isAdmin: true`
3. Confirmar que el token JWT no haya expirado
4. Revisar rate limiting si hay muchas requests

---

**Última actualización**: 31 de Diciembre de 2025
**Versión**: 1.0.0
