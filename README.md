# Iristrace Status Dashboard

Dashboard de monitorización de servicios NiFi y API para todos los stacks de Iristrace. Genera un `dashboard.html` estático servido por nginx, con regeneración automática vía cron.

## Estructura

```
iristrace-dashboard/
├── .env                ← configuración de entorno (puerto, intervalo, TZ)
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
├── nginx.conf
├── Dashboard.sh        ← script principal de monitorización
├── apis                ← fichero de stacks API (volumen)
├── nifis               ← fichero de stacks NiFi (volumen)
└── logo.png            ← logo (volumen)
```

## Configuración

Toda la configuración se gestiona desde `.env`:

```env
PORT=8081              # puerto expuesto en el host
REFRESH_INTERVAL=5     # minutos entre refrescso del dashboard
TZ=Europe/Madrid       # zona horaria para las marcas de tiempo
```

## Despliegue

```bash
docker compose up -d --build
```

El dashboard queda disponible en `http://<HOST>:${PORT}`.

## Comandos

```bash
# Estado del contenedor
docker compose ps

# Logs en tiempo real
docker compose logs -f

# Log de ejecuciones del cron
docker exec iristrace-dashboard tail -f /var/log/dashboard.log

# Forzar regeneración manual
docker exec iristrace-dashboard bash /app/Dashboard.sh

# Parar
docker compose down

# Reconstruir desde cero
docker compose down --rmi all && docker compose up -d --build
```

## Actualización del script

`Dashboard.sh` está montado como volumen, por lo que cualquier cambio en el fichero del host se aplica en la siguiente ejecución del cron. Para aplicarlo de forma inmediata:

```bash
docker exec iristrace-dashboard bash /app/Dashboard.sh
```

## Mover a otro servidor

```bash
# Exportar imagen
docker save iristrace-dashboard-dashboard | gzip > iristrace-dashboard.tar.gz

# En el servidor destino
docker load < iristrace-dashboard.tar.gz
docker compose up -d
```
