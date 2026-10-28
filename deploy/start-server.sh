#!/usr/bin/env bash
# ==============================================================================
# DiffX v3.5.0 — Mavenir Internal Web Server Launcher
# Developed by im_arg
# ==============================================================================

PORT=${1:-8094}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect primary server IP address (e.g. 10.x.x.x)
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1 2>/dev/null | awk '{print $7}' || echo "10.10.190.24")

echo "=========================================================="
echo " Starting DiffX v3.5.0 on Mavenir Internal Network"
echo " Target Port : $PORT"
echo " Detected IP : $SERVER_IP"
echo "=========================================================="

# Check if port is already in use
if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
        echo "[ERROR] Port $PORT is already in use by another service!"
        echo "Please specify a different port. Example: ./start-server.sh 8095"
        exit 1
    fi
fi

# Strategy 1: Docker (If available and daemon is running)
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "[INFO] Docker daemon active. Attempting Docker container on port $PORT..."
        docker rm -f diffx-web 2>/dev/null || true
        
        # Try running with nginx:alpine
        if docker run -d \
            --name diffx-web \
            --restart unless-stopped \
            -p "${PORT}:80" \
            -v "$SCRIPT_DIR/dist":/usr/share/nginx/html:ro \
            nginx:alpine 2>/dev/null; then
            
            sleep 1
            if curl -sI "http://localhost:${PORT}" | grep -q "200 OK"; then
                echo ""
                echo "=========================================================="
                echo " [OK] SUCCESS! DiffX is live via Docker container"
                echo " [OK] Health Check: HTTP 200 OK verified"
                echo " [OK] Accessible URL : http://${SERVER_IP}:${PORT}"
                echo " [OK] To stop        : ./stop-server.sh"
                echo "=========================================================="
                exit 0
            fi
        fi
        echo "[WARN] Docker run could not start (offline image missing or permissions). Trying Python 3..."
    fi
fi

# Strategy 2: Python 3 HTTP Server (Standard on 99% of Linux boxes, zero dependencies)
if command -v python3 >/dev/null 2>&1; then
    echo "[INFO] Starting standalone Python 3 HTTP server on port $PORT..."
    cd "$SCRIPT_DIR/dist"
    nohup python3 -m http.server "$PORT" > "$SCRIPT_DIR/diffx.log" 2>&1 &
    PID=$!
    echo "$PID" > "$SCRIPT_DIR/diffx.pid"
    
    sleep 1
    if kill -0 "$PID" 2>/dev/null; then
        echo ""
        echo "=========================================================="
        echo " [OK] SUCCESS! DiffX is running in background (PID: $PID)"
        echo " [OK] Health Check: Process verified running"
        echo " [OK] Accessible URL : http://${SERVER_IP}:${PORT}"
        echo " [OK] Server Logs    : tail -f $SCRIPT_DIR/diffx.log"
        echo " [OK] To stop        : ./stop-server.sh"
        echo "=========================================================="
        exit 0
    fi
    echo "[WARN] Python server failed to bind. Trying Node.js..."
fi

# Strategy 3: Node.js / npx serve
if command -v npx >/dev/null 2>&1; then
    echo "[INFO] Starting Node.js static server on port $PORT..."
    cd "$SCRIPT_DIR/dist"
    nohup npx -y serve -s . -l "$PORT" > "$SCRIPT_DIR/diffx.log" 2>&1 &
    PID=$!
    echo "$PID" > "$SCRIPT_DIR/diffx.pid"
    
    sleep 1
    echo ""
    echo "=========================================================="
    echo " [OK] SUCCESS! DiffX is running in background (PID: $PID)"
    echo " [OK] Accessible URL : http://${SERVER_IP}:${PORT}"
    echo " [OK] Server Logs    : tail -f $SCRIPT_DIR/diffx.log"
    echo " [OK] To stop        : ./stop-server.sh"
    echo "=========================================================="
    exit 0
fi

echo "[ERROR] Neither Docker, Python 3, nor Node.js was found on this server."
echo "Please install Docker, Python 3, or Nginx to host DiffX."
exit 1
