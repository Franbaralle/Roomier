@echo off
REM Script de backup automático de MongoDB para Windows
REM Configurar en el Programador de tareas de Windows para ejecución diaria

SET BACKUP_DIR=C:\backups\mongodb\roomier
SET TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%
SET DB_NAME=flutter_auth

REM Crear directorio de backups si no existe
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Realizar backup
echo Iniciando backup de MongoDB - %TIMESTAMP%
mongodump --db=%DB_NAME% --out="%BACKUP_DIR%\%TIMESTAMP%"

REM Comprimir backup (requiere 7-Zip instalado)
echo Comprimiendo backup...
"C:\Program Files\7-Zip\7z.exe" a -tzip "%BACKUP_DIR%\roomier_backup_%TIMESTAMP%.zip" "%BACKUP_DIR%\%TIMESTAMP%"
rmdir /s /q "%BACKUP_DIR%\%TIMESTAMP%"

REM Eliminar backups antiguos (más de 7 días)
forfiles /p "%BACKUP_DIR%" /m roomier_backup_*.zip /d -7 /c "cmd /c del @path" 2>nul

echo Backup completado: roomier_backup_%TIMESTAMP%.zip
