# 🚨 RESPUESTA A INCIDENTE DE SEGURIDAD - ENERO 2026

## Resumen del Incidente
**Fecha:** 2 de Enero 2026  
**Detectado por:** GitGuardian  
**Tipo:** Exposición de credenciales SMTP en repositorio público  
**Severidad:** CRÍTICA

## Credenciales Comprometidas
- ✅ EMAIL_USER (Gmail): `roomier2024@gmail.com`
- ✅ EMAIL_PASSWORD (App Password Gmail): `uyaw gmlh jpto enbr`
- ✅ JWT_SECRET: `4315ca2abab63d1fbaca130ac4039c90...`
- ✅ RESEND_API_KEY: `re_WN3nUFiQ_3PuUWnL8EnFkkbKQZtaULjHw`
- ✅ MONGODB_URI (parcialmente ofuscado)

## Acciones Correctivas Inmediatas

### 1. ⚠️ CAMBIAR CREDENCIALES (URGENTE)

#### Gmail App Password
1. Ve a https://myaccount.google.com/apppasswords
2. Revoca el password actual: `uyaw gmlh jpto enbr`
3. Genera un nuevo App Password
4. Actualiza en Railway Dashboard

#### Resend API Key
1. Ve a https://resend.com/api-keys
2. Revoca la API key: `re_WN3nUFiQ_3PuUWnL8EnFkkbKQZtaULjHw`
3. Genera una nueva API key
4. Actualiza en Railway Dashboard

#### JWT Secret
1. Genera un nuevo secret de 128 caracteres:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```
2. Actualiza en Railway Dashboard
3. ⚠️ Esto invalidará todas las sesiones activas (users deberán re-login)

#### MongoDB Atlas
La contraseña ya está parcialmente ofuscada (***), pero considera:
1. Cambiar contraseña del usuario `baralle2014`
2. Actualizar MONGODB_URI en Railway
3. Revisar logs de acceso en MongoDB Atlas

### 2. ✅ Eliminar Credenciales del Repositorio

#### Archivo afectado
- `RAILWAY_DEPLOY.md` líneas 123-124 (ya corregido)

#### Commit de corrección
```bash
git add RAILWAY_DEPLOY.md .gitignore SECURITY_INCIDENT_RESPONSE.md
git commit -m "SECURITY: Remove exposed credentials and improve .gitignore"
git push origin main
```

### 3. 🔒 Limpiar Historial de Git (OPCIONAL pero recomendado)

**⚠️ ADVERTENCIA:** Esto reescribirá el historial de Git. Coordina con tu equipo.

```bash
# Método 1: BFG Repo-Cleaner (recomendado)
# Instalar: https://rtyley.github.io/bfg-repo-cleaner/
bfg --replace-text passwords.txt --no-blob-protection
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Método 2: git filter-branch (más complejo)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch RAILWAY_DEPLOY.md" \
  --prune-empty --tag-name-filter cat -- --all
```

**Después de limpiar:**
```bash
git push --force --all
git push --force --tags
```

### 4. ✅ Mejoras Implementadas

- ✅ `.gitignore` actualizado con:
  - `.env` y variaciones
  - `credentials.json`
  - `secrets.json`
  - Archivos de logs
  - Archivos .pem y .key

- ✅ Documentación actualizada:
  - Valores de ejemplo en lugar de reales
  - Advertencias de seguridad agregadas

## Checklist de Verificación

### Inmediato (Próximas 2 horas)
- [ ] Revocar Gmail App Password
- [ ] Revocar Resend API Key
- [ ] Generar nuevo JWT_SECRET
- [ ] Actualizar todas las variables en Railway
- [ ] Verificar que el servicio funciona con nuevas credenciales
- [ ] Commit y push de cambios

### Corto Plazo (Próximos 2 días)
- [ ] Cambiar contraseña de MongoDB Atlas
- [ ] Revisar logs de MongoDB para accesos sospechosos
- [ ] Revisar logs de Gmail para envíos sospechosos
- [ ] Revisar logs de Resend para uso no autorizado
- [ ] Notificar a usuarios sobre invalidación de sesiones

### Mediano Plazo (Próxima semana)
- [ ] Decidir si limpiar historial de Git
- [ ] Implementar escaneo de secretos en CI/CD (pre-commit hooks)
- [ ] Considerar usar secrets management (Vault, AWS Secrets Manager)
- [ ] Implementar rotación automática de credenciales
- [ ] Capacitación en seguridad para el equipo

## Prevención Futura

### Git Pre-commit Hooks
```bash
# Instalar git-secrets
brew install git-secrets  # macOS
# o
sudo apt-get install git-secrets  # Linux

# Configurar en el repo
git secrets --install
git secrets --register-aws
```

### Herramientas de Escaneo
- ✅ GitGuardian (ya detectó el problema)
- Considerar: TruffleHog, Gitleaks
- Integrar en CI/CD pipeline

### Mejores Prácticas
1. ✅ Nunca commitear archivos .env
2. ✅ Usar valores de ejemplo en documentación
3. ✅ Mantener .gitignore actualizado
4. ⚠️ Revisar cada commit antes de push
5. ⚠️ Usar secrets management en producción
6. ⚠️ Rotar credenciales regularmente (cada 90 días)

## Contactos de Emergencia
- **GitGuardian Support:** support@gitguardian.com
- **GitHub Security:** https://github.com/security
- **Railway Support:** team@railway.app

## Lecciones Aprendidas
1. La documentación técnica no debe incluir credenciales reales
2. Los valores de ejemplo deben ser claramente identificables
3. El .gitignore debe ser completo desde el inicio
4. Las herramientas de escaneo (GitGuardian) son esenciales
5. Respuesta rápida minimiza el impacto

## Estado Actual
- ✅ Credenciales eliminadas de documentación
- ✅ .gitignore mejorado
- ⚠️ Credenciales aún NO cambiadas (URGENTE)
- ⚠️ Historial de Git aún contiene credenciales

---
**Última actualización:** 2 de Enero 2026  
**Responsable:** Equipo Roomier  
**Estado:** EN PROGRESO
