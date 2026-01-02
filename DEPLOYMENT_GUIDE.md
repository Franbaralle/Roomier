# 📚 Guía de Despliegue a Producción - Roomier

## 📋 Requisitos Previos

- Servidor Ubuntu 20.04+ o Debian 11+
- Dominio apuntando a tu servidor
- Acceso root o sudo
- MongoDB instalado

## 🚀 Paso 1: Preparar el Servidor

### Instalar Node.js, MongoDB y dependencias

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org

# Iniciar MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Instalar Nginx
sudo apt install -y nginx

# Instalar PM2 globalmente
sudo npm install -g pm2
```

## 📦 Paso 2: Subir el Código al Servidor

### Opción A: Con Git

```bash
# En tu máquina local, crear repositorio
cd /ruta/a/Roomier/backend
git init
git add .
git commit -m "Initial commit"

# Subir a GitHub/GitLab (privado)
git remote add origin tu-repositorio.git
git push -u origin main

# En el servidor
cd /var/www
sudo git clone tu-repositorio.git roomier
cd roomier
sudo npm install --production
```

### Opción B: Con SCP/SFTP

```bash
# Desde tu máquina local
scp -r backend/ usuario@tu-servidor:/var/www/roomier/
```

## 🔧 Paso 3: Configurar Variables de Entorno

```bash
cd /var/www/roomier
sudo nano .env.production
```

Edita el archivo con tus datos reales:

```env
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb://127.0.0.1:27017/flutter_auth
JWT_SECRET=tu_clave_super_segura_generada_aqui
JWT_EXPIRES_IN=24h
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=tu_email@gmail.com
EMAIL_PASSWORD=tu_password_de_aplicacion
ALLOWED_ORIGINS=https://tudominio.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=info
LOG_FILE=./logs/app.log
```

**Generar JWT_SECRET seguro:**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## 🔐 Paso 4: Configurar HTTPS con Let's Encrypt

```bash
cd /var/www/roomier
sudo chmod +x scripts/setup-ssl.sh

# Editar el script con tu dominio y email
sudo nano scripts/setup-ssl.sh

# Ejecutar
sudo ./scripts/setup-ssl.sh
```

## 🌐 Paso 5: Configurar Nginx

```bash
# Copiar configuración
sudo cp config/nginx.conf /etc/nginx/sites-available/roomier

# Editar con tu dominio real
sudo nano /etc/nginx/sites-available/roomier
# Reemplazar "tudominio.com" con tu dominio real

# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/roomier /etc/nginx/sites-enabled/

# Remover sitio por defecto
sudo rm /etc/nginx/sites-enabled/default

# Verificar configuración
sudo nginx -t

# Reiniciar Nginx
sudo systemctl restart nginx
```

## ⚙️ Paso 6: Iniciar Aplicación con PM2

```bash
cd /var/www/roomier

# Iniciar con configuración de producción
pm2 start ecosystem.config.js --env production

# Guardar configuración para auto-inicio
pm2 save

# Configurar PM2 para iniciar al arrancar el servidor
pm2 startup systemd
# Ejecutar el comando que te muestra PM2

# Ver logs
pm2 logs roomier-api

# Monitorear
pm2 monit
```

## 💾 Paso 7: Configurar Backups Automáticos

### En Linux:

```bash
# Dar permisos de ejecución
sudo chmod +x scripts/backup-mongodb.sh

# Editar variables si es necesario
sudo nano scripts/backup-mongodb.sh

# Probar backup manual
sudo ./scripts/backup-mongodb.sh

# Configurar cron para backup diario a las 3 AM
sudo crontab -e
# Agregar la línea:
0 3 * * * /var/www/roomier/scripts/backup-mongodb.sh >> /var/log/mongodb-backup.log 2>&1
```

### En Windows Server:

1. Abrir "Programador de tareas"
2. Crear tarea básica
3. Trigger: Diariamente a las 3:00 AM
4. Acción: Iniciar programa
5. Programa: `C:\ruta\a\Roomier\backend\scripts\backup-mongodb.bat`

## 🔄 Paso 8: Actualizar la App Flutter

Edita la URL del API en tu app Flutter:

```dart
// lib/auth_service.dart o donde esté configurada la URL base
final String baseUrl = 'https://tudominio.com/api';
```

Regenera el APK:

```bash
flutter build apk --release
```

## ✅ Verificación

### Verificar que todo funcione:

```bash
# Estado de PM2
pm2 status

# Logs en tiempo real
pm2 logs roomier-api

# Estado de Nginx
sudo systemctl status nginx

# Estado de MongoDB
sudo systemctl status mongod

# Verificar certificado SSL
sudo certbot certificates

# Probar API
curl https://tudominio.com/api
```

## 🛠️ Comandos Útiles

### PM2:
```bash
pm2 restart roomier-api    # Reiniciar app
pm2 stop roomier-api        # Detener app
pm2 delete roomier-api      # Eliminar app
pm2 logs roomier-api        # Ver logs
pm2 monit                   # Monitor en tiempo real
```

### Nginx:
```bash
sudo nginx -t               # Verificar configuración
sudo systemctl restart nginx # Reiniciar
sudo systemctl reload nginx  # Recargar sin downtime
```

### MongoDB:
```bash
mongodump --db=flutter_auth --out=/backups/manual
mongorestore --db=flutter_auth /backups/manual/flutter_auth
```

## 🔒 Seguridad Adicional

### Firewall (UFW):
```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
```

### MongoDB (solo local):
```bash
sudo nano /etc/mongod.conf
# Verificar que tenga:
# net:
#   bindIp: 127.0.0.1

sudo systemctl restart mongod
```

### Fail2Ban (protección contra fuerza bruta):
```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 📊 Monitoreo

### Ver logs de aplicación:
```bash
tail -f /var/www/roomier/logs/app.log
```

### Monitorear uso de recursos:
```bash
htop
```

## 🆘 Troubleshooting

### Error de conexión a MongoDB:
```bash
sudo systemctl status mongod
sudo journalctl -u mongod -f
```

### Error 502 Bad Gateway:
```bash
pm2 status
pm2 logs roomier-api
sudo nginx -t
```

### Renovación SSL falla:
```bash
sudo certbot renew --dry-run
sudo systemctl reload nginx
```

## 📝 Notas Importantes

1. **Cambia todas las credenciales** en `.env.production`
2. **Configura backups** en un servicio cloud (AWS S3, Google Cloud Storage)
3. **Monitorea logs** regularmente
4. **Actualiza el sistema** periódicamente: `sudo apt update && sudo apt upgrade`
5. **Prueba los backups** restaurándolos en un ambiente de prueba

## 🔄 Actualizaciones

Para actualizar la aplicación:

```bash
cd /var/www/roomier
git pull origin main  # Si usas Git
npm install --production
pm2 restart roomier-api
```

---

¡Listo! Tu aplicación Roomier está desplegada en producción con HTTPS, backups automáticos y configuración optimizada. 🎉
