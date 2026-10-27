# DiffX v3.5.0 — Mavenir Internal Deployment Guide

This package contains everything needed to deploy DiffX on Mavenir's internal network (e.g. `10.10.190.24` or any internal lab VM / Docker host).

---

## Quick Start (1 Command)

To run DiffX on port `8094` (or any custom port):

```bash
# Default port 8094
./start-server.sh

# Or specify your desired port
./start-server.sh 8080
```

The script automatically detects if **Docker**, **Python 3**, or **Nginx** is present, starts DiffX in the background, and prints your internal URL:
```
http://<SERVER_IP>:8094
```

To stop the server at any time:
```bash
./stop-server.sh
```

---

## Deployment Options

### Option 1: Docker / Docker Compose
```bash
# Run using docker compose
docker compose up -d

# Or run directly with docker run:
docker run -d --name diffx-web --restart unless-stopped -p 8094:80 -v $(pwd)/dist:/usr/share/nginx/html:ro nginx:alpine
```

### Option 2: Standalone Linux Server (Python 3)
```bash
cd dist
nohup python3 -m http.server 8094 > ../diffx.log 2>&1 &
```

### Option 3: Standard Enterprise Nginx
Copy `nginx.conf` to `/etc/nginx/conf.d/diffx.conf`, edit `root` to point to the `dist` directory, and run `nginx -s reload`.
