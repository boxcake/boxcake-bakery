#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_CONFIG_DIR="${SCRIPT_DIR}/web-config"

echo -e "${YELLOW}🔧 Rebuilding web interface...${NC}"

# Check if directories exist
if [ ! -d "$WEB_CONFIG_DIR/frontend" ]; then
    echo -e "${RED}❌ Frontend directory not found: $WEB_CONFIG_DIR/frontend${NC}"
    exit 1
fi

cd "$WEB_CONFIG_DIR/frontend"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing npm dependencies...${NC}"
    npm install
fi

# Build the frontend
echo -e "${YELLOW}⚛️  Building React frontend...${NC}"
npm run build

# Check if build was successful
if [ ! -f "../build/index.html" ]; then
    echo -e "${RED}❌ Build failed - index.html not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend build complete${NC}"

# Restart the service
echo -e "${YELLOW}🔄 Restarting web configuration service...${NC}"
systemctl restart homelab-web-config

# Wait a moment and check status
sleep 2
if systemctl is-active --quiet homelab-web-config; then
    echo -e "${GREEN}✅ Service restarted successfully${NC}"

    # Get host IP
    HOST_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}🌐 Web interface available at: http://${HOST_IP}:8080${NC}"
else
    echo -e "${RED}❌ Service failed to start${NC}"
    echo -e "${YELLOW}💡 Check service status: systemctl status homelab-web-config${NC}"
    exit 1
fi