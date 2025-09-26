#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_CONFIG_DIR="${SCRIPT_DIR}/web-config"

echo -e "${YELLOW}🔧 Fixing deployment command paths...${NC}"

# Update systemd service with proper PATH
echo -e "${YELLOW}📝 Updating systemd service...${NC}"
cat > /etc/systemd/system/homelab-web-config.service << EOF
[Unit]
Description=Home Lab Web Configuration Interface
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WEB_CONFIG_DIR}/backend
Environment=PATH=${WEB_CONFIG_DIR}/backend/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=${WEB_CONFIG_DIR}/backend
ExecStart=${WEB_CONFIG_DIR}/backend/venv/bin/python main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload

# Restart the service
echo -e "${YELLOW}🔄 Restarting web service...${NC}"
systemctl restart homelab-web-config

# Wait and check status
sleep 2
if systemctl is-active --quiet homelab-web-config; then
    echo -e "${GREEN}✅ Service updated and restarted successfully${NC}"

    # Test endpoints
    if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Web service is responding${NC}"
    else
        echo -e "${RED}❌ Web service not responding${NC}"
    fi

    HOST_IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}🌐 Ready for deployment testing at: http://${HOST_IP}:8080${NC}"

else
    echo -e "${RED}❌ Service failed to start${NC}"
    echo -e "${YELLOW}💡 Check logs: journalctl -u homelab-web-config -n 20${NC}"
fi

echo -e "${YELLOW}💡 The deployment process will now automatically find Ansible commands${NC}"
echo -e "${YELLOW}   and install missing dependencies as needed.${NC}"