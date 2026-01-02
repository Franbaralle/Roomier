# ✅ Checklist de Despliegue Rápido

## Antes de Subir al Servidor

- [ ] Generar JWT_SECRET seguro: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`
- [ ] Tener dominio apuntando al servidor (DNS configurado)
- [ ] Tener credenciales de email configuradas
- [ ] Hacer backup local del código y base de datos

## En el Servidor

### 1. Instalación Básica
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs nginx mongodb-org
sudo npm install -g pm2
```

### 2. Subir Código
```bash
cd /var/www
sudo git clone tu-repo roomier
cd roomier
sudo npm install --production
```

### 3. Configurar .env.production
```bash
sudo nano .env.production
# Completar todos los valores
```

### 4. SSL (Let's Encrypt)
```bash
sudo chmod +x scripts/setup-ssl.sh
sudo nano scripts/setup-ssl.sh  # Editar dominio y email
sudo ./scripts/setup-ssl.sh
```

### 5. Nginx
```bash
sudo cp config/nginx.conf /etc/nginx/sites-available/roomier
sudo nano /etc/nginx/sites-available/roomier  # Cambiar tudominio.com
sudo ln -s /etc/nginx/sites-available/roomier /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### 6. PM2
```bash
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup systemd  # Ejecutar el comando que muestra
```

### 7. Backups
```bash
sudo chmod +x scripts/backup-mongodb.sh
sudo crontab -e
# Agregar: 0 3 * * * /var/www/roomier/scripts/backup-mongodb.sh >> /var/log/mongodb-backup.log 2>&1
```

### 8. Firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Verificación Final

- [ ] `curl https://tudominio.com/api` responde
- [ ] `pm2 status` muestra app corriendo
- [ ] `sudo systemctl status nginx` activo
- [ ] `sudo systemctl status mongod` activo
- [ ] `sudo certbot certificates` muestra certificado válido
- [ ] Logs limpios: `pm2 logs roomier-api`
- [ ] Backup manual funciona: `./scripts/backup-mongodb.sh`

## Actualizar App Flutter

```bash
# En auth_service.dart u otro archivo de configuración:
final String baseUrl = 'https://tudominio.com/api';

# Regenerar APK
flutter build apk --release
```

## URLs de Prueba

- API: https://tudominio.com/api
- Health check: https://tudominio.com/api (debe responder "Servidor en funcionamiento")

---

**Tiempo estimado:** 30-45 minutos

**Siguiente paso:** Monitorear logs durante las primeras horas y hacer pruebas desde la app móvil.
