#!/usr/bin/env bash
# TrueNAS SCALE — Ollama LLM Deployment with Intel Arc GPU
# Run this script on TrueNAS as the 'assistant' user (has sudo)
#
# IMPORTANT: TrueNAS SCALE requires UID/GID 568 (apps user) for all
# containerized services. This is the same pattern used by every stack
# in /mnt/kevbot-store/stacks/ (jellyfin, sonarr, radarr, etc.)
# Using the wrong UID causes ZFS permission errors on datasets.
#
# GPU passthrough uses the same pattern as the Jellyfin stack:
#   devices: /dev/dri/:/dev/dri/
#   group_add: 107 (render), 44 (video)
#
# Usage:
#   bash deploy-ollama.sh                  # Deploy with default model (qwen2.5:7b)
#   bash deploy-ollama.sh qwen2.5:7b      # Deploy with specific model
#   bash deploy-ollama.sh --stop           # Stop and remove container
#   bash deploy-ollama.sh --logs           # View container logs
#   bash deploy-ollama.sh --status         # Check status
#   bash deploy-ollama.sh --pull MODEL     # Pull a new model

set -euo pipefail

MODEL="${1:-qwen2.5:7b}"
CONTAINER_NAME="ollama"
OLLAMA_PORT="11434"
DATA_DIR="/mnt/kevbot-store/assistant/ollama-data"

# TrueNAS SCALE uses UID/GID 568 (apps user) for all containerized services
# This is required for proper file permissions on ZFS datasets
OLLAMA_UID=568
OLLAMA_GID=568

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; }
fail() { echo -e "  ${RED}❌${NC}  $1"; }

# Handle special commands
case "${1:-}" in
    --stop)
        echo "Stopping Ollama..."
        sudo docker stop $CONTAINER_NAME 2>/dev/null && sudo docker rm $CONTAINER_NAME 2>/dev/null
        ok "Stopped and removed"
        exit 0
        ;;
    --logs)
        sudo docker logs -f $CONTAINER_NAME 2>&1
        exit 0
        ;;
    --status)
        echo "=== Container ==="
        sudo docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Not running"
        echo ""
        echo "=== GPU ==="
        sudo docker exec $CONTAINER_NAME ls /dev/dri/ 2>/dev/null || echo "N/A"
        echo ""
        echo "=== Models ==="
        curl -s http://localhost:$OLLAMA_PORT/api/tags 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
for m in d.get('models',[]):
    print(f\"  {m['name']} ({m.get('size',0)/1e9:.1f}GB)\")
" 2>/dev/null || echo "API not responding"
        exit 0
        ;;
    --pull)
        MODEL="${2:-qwen2.5:7b}"
        echo "Pulling $MODEL..."
        sudo docker exec $CONTAINER_NAME ollama pull "$MODEL"
        ok "Model $MODEL pulled"
        exit 0
        ;;
esac

echo "═══════════════════════════════════════════════════"
echo "  Ollama LLM — Intel Arc A750 GPU"
echo "═══════════════════════════════════════════════════"
echo ""

# Step 1: Prerequisites
echo "▶ Prerequisites..."

if ! command -v docker &>/dev/null; then
    fail "Docker not found"
    exit 1
fi
ok "Docker: $(sudo docker --version)"

if [ ! -d "/dev/dri" ]; then
    fail "/dev/dri not found"
    exit 1
fi
ok "GPU: $(ls /dev/dri/)"

# Step 2: Data directory
echo ""
echo "▶ Data directory..."
sudo mkdir -p "$DATA_DIR"
sudo chown $OLLAMA_UID:$OLLAMA_GID "$DATA_DIR"
ok "$DATA_DIR (UID=$OLLAMA_UID, GID=$OLLAMA_GID)"

# Step 3: Stop existing
echo ""
echo "▶ Deploying..."
sudo docker stop $CONTAINER_NAME 2>/dev/null && sudo docker rm $CONTAINER_NAME 2>/dev/null

# Step 4: Run Ollama with GPU passthrough (same pattern as Jellyfin)
# TrueNAS SCALE uses UID/GID 568 (apps user) for all containerized services
sudo docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $OLLAMA_PORT:$OLLAMA_PORT \
    -v "$DATA_DIR:/root/.ollama" \
    --user $OLLAMA_UID:$OLLAMA_GID \
    --device /dev/dri/:/dev/dri/ \
    --group-add 107 \
    --group-add 44 \
    ollama/ollama:latest

if [ $? -eq 0 ]; then
    ok "Container started"
else
    fail "Container failed to start"
    exit 1
fi

# Step 5: Wait for API
echo ""
echo "▶ Waiting for API..."
for i in $(seq 1 30); do
    if curl -s http://localhost:$OLLAMA_PORT/api/tags >/dev/null 2>&1; then
        ok "API ready"
        break
    fi
    if [ $i -eq 30 ]; then
        fail "API failed to start"
        sudo docker logs $CONTAINER_NAME 2>&1 | tail -10
        exit 1
    fi
    sleep 1
done

# Step 6: Pull model
echo ""
echo "▶ Pulling: $MODEL (this takes 10-30 min)..."
sudo docker exec $CONTAINER_NAME ollama pull "$MODEL" 2>&1
ok "Model ready"

# Step 7: Verify
echo ""
echo "▶ Verifying..."
GPU=$(sudo docker exec $CONTAINER_NAME ls /dev/dri/renderD128 2>/dev/null)
[ -n "$GPU" ] && ok "GPU accessible" || warn "GPU may not be accessible"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  ✅ Deployment Complete"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  API:     http://192.168.2.148:$OLLAMA_PORT"
echo "  Model:   $MODEL"
echo "  GPU:     Intel Arc A750"
echo "  Data:    $DATA_DIR"
echo ""
echo "  Test from ThinkCentre:"
echo "    curl http://192.168.2.148:$OLLAMA_PORT/api/generate \\"
echo "      -d '{\"model\":\"$MODEL\",\"prompt\":\"hello\",\"stream\":false}'"
echo ""
echo "  Commands:"
echo "    bash $0 --status"
echo "    bash $0 --logs"
echo "    bash $0 --pull llama3.1:8b"
echo "    bash $0 --stop"
