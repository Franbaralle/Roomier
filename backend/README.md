# Roomier Backend API

API REST para la aplicación Roomier - Match de Roommates

🔄 Última actualización: 8 de Enero de 2026

## 🚀 Deploy Rápido en Railway

**Sigue la guía completa:** [RAILWAY_DEPLOY.md](../RAILWAY_DEPLOY.md)

**Pasos rápidos:**
1. Crear cuenta MongoDB Atlas (gratis)
2. Pushear a GitHub
3. Conectar con Railway
4. Configurar variables de entorno
5. ✅ ¡Listo!

## 🛠️ Desarrollo Local

### Requisitos
- Node.js 16+
- MongoDB local o Atlas
- NPM o Yarn

### Instalación

```bash
npm install
```

### Configuración

Crea un archivo `.env` basado en `.env.example`:

```bash
cp .env.example .env
```

Edita `.env` con tus credenciales locales.

### Ejecutar

```bash
# Desarrollo
npm run dev

# Producción
npm run prod

# Con PM2
npm run pm2:start
```

### Testing

```bash
# Todos los tests
npm test

# Con watch mode
npm run test:watch

# Con coverage
npm run test:coverage
```

## 📁 Estructura

```
backend/
├── app.js              # Punto de entrada
├── config/            # Configuraciones
├── controllers/       # Lógica de negocio
├── middleware/        # Middlewares (auth, rate limit)
├── models/           # Modelos de Mongoose
├── routes/           # Rutas de la API
├── scripts/          # Scripts de utilidad
├── tests/            # Tests automatizados
└── utils/            # Utilidades (logger)
```

## 🔐 Seguridad

- ✅ Bcrypt para contraseñas
- ✅ JWT tokens
- ✅ Rate limiting
- ✅ CORS configurado
- ✅ Validación de inputs

## 📊 Endpoints Principales

### Autenticación
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `POST /api/auth/reset-password` - Reset password

### Usuarios
- `GET /api/profile/:username` - Ver perfil
- `PUT /api/edit-profile/interests` - Editar intereses
- `PUT /api/edit-profile/habits` - Editar hábitos
- `PUT /api/edit-profile/housing` - Editar vivienda

### Matching
- `GET /api/home` - Obtener matches potenciales
- `POST /api/home/match` - Hacer match

### Chat
- `GET /api/chat` - Listar chats
- `GET /api/chat/:chatId` - Ver chat
- `POST /api/chat/:chatId/message` - Enviar mensaje

### Moderación
- `POST /api/moderation/report` - Reportar usuario
- `POST /api/moderation/block` - Bloquear usuario

### Admin
- `GET /api/admin/reports` - Ver reportes
- `PUT /api/admin/reports/:id` - Actualizar reporte
- `POST /api/admin/users/:id/action` - Acción sobre usuario

### Analytics
- `POST /api/analytics/track` - Registrar evento
- `GET /api/analytics/my-stats` - Mis estadísticas
- `GET /api/analytics/global-stats` - Estadísticas globales (admin)

## 🌍 Variables de Entorno

Ver `.env.example` para lista completa.

**Críticas para producción:**
- `MONGODB_URI` - Connection string de MongoDB
- `JWT_SECRET` - Clave secreta para JWT
- `ALLOWED_ORIGINS` - Dominios permitidos para CORS
- `RESEND_API_KEY` - API key para emails (Resend)
- `CLOUDINARY_CLOUD_NAME` - Cloud name de Cloudinary
- `CLOUDINARY_API_KEY` - API key de Cloudinary
- `CLOUDINARY_API_SECRET` - API secret de Cloudinary

## 📷 Almacenamiento de Imágenes (Cloudinary)

Las imágenes de perfil se almacenan en Cloudinary en lugar de MongoDB.

**Configuración:**
1. Crear cuenta en [cloudinary.com](https://cloudinary.com)
2. Copiar credenciales del dashboard
3. Agregar variables de entorno (ver arriba)

**Migración de imágenes existentes:**
```bash
# Ver guía completa
cat CLOUDINARY_MIGRATION.md

# Ejecutar migración
node migrateImagesToCloudinary.js
```

**Beneficios:**
- ✅ CDN global (carga rápida)
- ✅ Optimización automática de imágenes
- ✅ Reduce tamaño de DB en ~90%
- ✅ Transformaciones on-the-fly
- ✅ 25GB gratis/mes

## 📝 Logs

Los logs se guardan en `./logs/`:
- `app.log` - Todos los logs
- `error.log` - Solo errores

## 🔄 Backups

Scripts disponibles en `./scripts/`:
- `backup-mongodb.sh` (Linux)
- `backup-mongodb.bat` (Windows)

Configurar como cron job o tarea programada.

## 📦 Scripts NPM

```bash
npm start          # Iniciar servidor
npm run dev        # Modo desarrollo
npm run prod       # Modo producción
npm test           # Ejecutar tests
npm run pm2:start  # Iniciar con PM2
npm run pm2:logs   # Ver logs de PM2
```

## 🐛 Troubleshooting

### Error de conexión a MongoDB
```bash
# Verifica que MongoDB esté corriendo
# Local: mongod
# Atlas: verifica Network Access y Database Access
```

### Tests fallan
```bash
# Asegúrate de tener MongoDB corriendo
# Los tests usan una DB separada para testing
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una branch (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto es privado y confidencial.

## 🔗 Links

- [Guía de Deploy en Railway](../RAILWAY_DEPLOY.md)
- [Guía de Deploy General](../DEPLOYMENT_GUIDE.md)
- [Checklist de Deploy](../DEPLOYMENT_CHECKLIST.md)
- [Migración a Cloudinary](./CLOUDINARY_MIGRATION.md)
- [Pasos de Deployment Cloudinary](../CLOUDINARY_DEPLOYMENT_STEPS.md)
- [Análisis de la App](../ANALISIS_APP.txt)
