#!/bin/bash

# Script de backup automático de MongoDB para Roomier
# Configurar este script para ejecutarse diariamente con cron

# Variables de configuración
BACKUP_DIR="/var/backups/mongodb/roomier"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_NAME="flutter_auth"
RETENTION_DAYS=7

# Crear directorio de backups si no existe
mkdir -p $BACKUP_DIR

# Realizar backup
echo "Iniciando backup de MongoDB - $TIMESTAMP"
mongodump --db=$DB_NAME --out=$BACKUP_DIR/$TIMESTAMP

# Comprimir backup
echo "Comprimiendo backup..."
cd $BACKUP_DIR
tar -czf roomier_backup_$TIMESTAMP.tar.gz $TIMESTAMP
rm -rf $TIMESTAMP

# Eliminar backups antiguos (más de RETENTION_DAYS días)
echo "Eliminando backups antiguos..."
find $BACKUP_DIR -name "roomier_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completado: roomier_backup_$TIMESTAMP.tar.gz"

# Opcional: Subir a cloud storage (ejemplo con AWS S3)
# aws s3 cp $BACKUP_DIR/roomier_backup_$TIMESTAMP.tar.gz s3://tu-bucket/backups/

# Opcional: Enviar notificación por email
# echo "Backup completado exitosamente" | mail -s "Backup MongoDB - $TIMESTAMP" tu_email@gmail.com
