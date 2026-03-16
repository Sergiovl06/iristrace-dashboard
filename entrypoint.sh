#!/bin/bash
set -e

INTERVAL="${REFRESH_INTERVAL:-5}"

cd /app

echo "[entrypoint] Generando dashboard inicial..."
bash /app/Dashboard.sh

echo "[entrypoint] Configurando cron cada ${INTERVAL} minutos..."
echo "*/${INTERVAL} * * * * bash /app/Dashboard.sh >> /var/log/dashboard.log 2>&1" \
    > /etc/crontabs/root

echo "[entrypoint] Iniciando crond..."
crond -l 8

echo "[entrypoint] Iniciando nginx..."
exec nginx -g "daemon off;"
