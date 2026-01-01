#!/bin/bash

# Script para configurar SSL con Let's Encrypt en el servidor
# Ejecutar en el servidor de producción con Ubuntu/Debian

DOMAIN="tudominio.com"
EMAIL="tu_email@gmail.com"

echo "==================================="
echo "Configurando SSL para Roomier"
echo "==================================="

# Actualizar sistema
echo "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Certbot y el plugin de Nginx
echo "Instalando Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Verificar que Nginx esté instalado
if ! command -v nginx &> /dev/null; then
    echo "Instalando Nginx..."
    sudo apt install -y nginx
fi

# Crear directorio para validación de Let's Encrypt
sudo mkdir -p /var/www/certbot

# Obtener certificado SSL
echo "Obteniendo certificado SSL de Let's Encrypt..."
sudo certbot certonly --nginx \
    -d $DOMAIN \
    -d www.$DOMAIN \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal

# Configurar renovación automática
echo "Configurando renovación automática..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'") | crontab -

# Verificar configuración de Nginx
sudo nginx -t

# Recargar Nginx
echo "Recargando Nginx..."
sudo systemctl reload nginx

echo "==================================="
echo "SSL configurado exitosamente!"
echo "Tu sitio ahora está disponible en https://$DOMAIN"
echo "==================================="
