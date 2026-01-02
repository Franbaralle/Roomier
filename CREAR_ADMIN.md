# 🔐 Gestión de Usuarios Admin - Roomier

## Crear un Administrador

### Opción 1: Usar el script makeAdmin.js (RECOMENDADO)

```bash
cd backend
node makeAdmin.js <username>
```

**Ejemplo:**
```bash
node makeAdmin.js juan
```

**Salida:**
```
✅ Usuario "juan" ahora es administrador
📧 Email: juan@example.com
📅 Cuenta creada: 25/12/2024
```

---

### Opción 2: MongoDB Compass (GUI)

1. Abrir MongoDB Compass
2. Conectar a `mongodb://127.0.0.1:27017`
3. Seleccionar base de datos `flutter_auth`
4. Colección `users`
5. Buscar tu usuario
6. Agregar campo: `isAdmin: true`
7. Guardar

---

### Opción 3: Mongo Shell (Terminal)

```bash
mongosh
use flutter_auth
db.users.updateOne(
  { username: "juan" },
  { $set: { isAdmin: true } }
)
```

---

## Comandos del Script

### Ver ayuda
```bash
node makeAdmin.js
```

### Hacer admin a un usuario
```bash
node makeAdmin.js <username>
```

### Listar todos los admins
```bash
node makeAdmin.js --list
```

### Remover permisos de admin
```bash
node makeAdmin.js <username> --remove
```

---

## Acceder al Panel Admin

Una vez que tengas un usuario con `isAdmin: true`:

1. **Iniciar sesión** en la app con ese usuario
2. **Navegar** a la ruta `/admin` (o agregar botón en perfil)
3. El middleware verificará el token JWT + flag isAdmin
4. Si es válido, verás el panel completo

### Agregar botón al perfil (opcional)

En `lib/profile_page.dart`, agregar:

```dart
if (isCurrentUser && isAdmin) {
  ElevatedButton.icon(
    onPressed: () {
      Navigator.pushNamed(context, '/admin');
    },
    icon: Icon(Icons.admin_panel_settings),
    label: Text('Panel Admin'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
    ),
  ),
}
```

---

## Verificar si un usuario es admin

### Desde Node.js
```javascript
const User = require('./models/user');

const user = await User.findOne({ username: 'juan' });
console.log(user.isAdmin); // true o false
```

### Desde MongoDB Shell
```javascript
db.users.findOne({ username: "juan" }, { username: 1, isAdmin: 1 })
```

---

## Seguridad

✅ **Implementado:**
- Middleware `isAdmin` verifica permisos
- JWT token requerido
- Logging de todas las acciones admin
- Rutas protegidas (403 Forbidden si no es admin)

⚠️ **Recomendado para producción:**
- 2FA para cuentas admin
- IP whitelist
- Rotación de tokens más frecuente
- Auditoría de acciones con timestamps

---

## Troubleshooting

### "Usuario no encontrado"
El usuario debe existir primero. Regístrate normalmente en la app, luego usa el script.

### "Acceso denegado. Solo administradores."
Verifica que:
1. El usuario tenga `isAdmin: true` en la BD
2. El token JWT sea válido
3. Estés enviando el header `Authorization: Bearer <token>`

### Panel admin no carga
1. Verifica que la ruta `/admin` esté registrada en `main.dart`
2. El backend debe estar corriendo
3. Revisa logs en `backend/logs/error.log`

---

## Flujo Completo

1. **Registro normal**: Crear cuenta en la app
2. **Hacer admin**: `node makeAdmin.js miusuario`
3. **Login**: Iniciar sesión en la app
4. **Acceder**: Ir a `/admin` o usar botón en perfil
5. **Gestionar**: Ver reportes, tomar acciones, etc.

---

Última actualización: 31 de Diciembre de 2025
