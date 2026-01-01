module.exports = {
  apps: [{
    name: 'roomier-api',
    script: './app.js',
    instances: 2, // Número de instancias (usar 'max' para usar todos los CPUs)
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    // Reintentos en caso de fallo
    exp_backoff_restart_delay: 100,
    // Configuración de monitoreo
    min_uptime: '10s',
    max_restarts: 10
  }]
};
