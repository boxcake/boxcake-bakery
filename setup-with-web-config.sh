#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the actual script directory (works with sudo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_CONFIG_DIR="${SCRIPT_DIR}/web-config"

# Banner
echo -e "${BLUE}"
cat << 'EOF'
🏠 Boxcake Bakery - Web Configuration Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Interactive web-based configuration for your
Kubernetes home lab deployment.

Features:
• User-friendly configuration wizard
• Real-time validation
• Service selection
• Network customization
• Live deployment tracking
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root or with sudo${NC}"
    echo -e "${YELLOW}💡 Usage: sudo ./setup-with-web-config.sh${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting web configuration setup...${NC}"
echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "  Script directory: ${SCRIPT_DIR}"
echo -e "  Web config directory: ${WEB_CONFIG_DIR}"
echo ""

# Check if web-config directory exists
if [ ! -d "$WEB_CONFIG_DIR" ]; then
    echo -e "${RED}❌ Web config directory not found: $WEB_CONFIG_DIR${NC}"
    echo -e "${YELLOW}💡 Make sure you're running this from the correct directory${NC}"
    exit 1
fi

# Step 1: Update system packages
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt-get update -qq

# Step 2: Install Python and Node.js
echo -e "${YELLOW}🐍 Installing Python and Node.js...${NC}"

# Install Python 3 and pip if not present
if ! command -v python3 >/dev/null 2>&1; then
    apt-get install -y python3 python3-pip python3-venv
else
    echo -e "${GREEN}✅ Python3 already installed${NC}"
fi

# Install Node.js (for building the frontend)
if ! command -v node >/dev/null 2>&1; then
    echo -e "${YELLOW}📦 Installing Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
else
    echo -e "${GREEN}✅ Node.js already installed${NC}"
fi

# Step 3: Set up Python backend
echo -e "${YELLOW}🔧 Setting up Python backend...${NC}"

cd "${WEB_CONFIG_DIR}/backend"

# Create virtual environment
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment and install dependencies
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✅ Python backend configured${NC}"

# Step 4: Build React frontend
echo -e "${YELLOW}⚛️  Building React frontend...${NC}"

cd "${WEB_CONFIG_DIR}/frontend"

# Install npm dependencies
npm install

# Build the frontend
npm run build

echo -e "${GREEN}✅ React frontend built${NC}"

# Step 5: Create systemd service for the web interface
echo -e "${YELLOW}🔧 Creating systemd service...${NC}"

cat > /etc/systemd/system/homelab-web-config.service << EOF
[Unit]
Description=Home Lab Web Configuration Interface
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${WEB_CONFIG_DIR}/backend
Environment=PATH=${WEB_CONFIG_DIR}/backend/venv/bin
ExecStart=${WEB_CONFIG_DIR}/backend/venv/bin/python main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable homelab-web-config
systemctl start homelab-web-config

echo -e "${GREEN}✅ Web configuration service started${NC}"

# Step 6: Wait for service to be ready
echo -e "${YELLOW}⏳ Waiting for web interface to be ready...${NC}"

RETRY_COUNT=0
MAX_RETRIES=30

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Web interface is ready${NC}"
        break
    fi
    echo -e "   Waiting for web interface... ($((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ Web interface failed to start${NC}"
    echo -e "${YELLOW}💡 Check the service status: systemctl status homelab-web-config${NC}"
    exit 1
fi

# Step 7: Get host IP address
HOST_IP=$(hostname -I | awk '{print $1}')

# Final information
echo -e "${GREEN}"
cat << EOF
🎉 Web configuration interface is ready!

🌐 Access the configuration wizard:
   http://${HOST_IP}:8080
   http://localhost:8080 (if accessing locally)

📋 What to do next:
   1. Open the URL above in your web browser
   2. Follow the configuration wizard
   3. Review your settings
   4. Click "Deploy Now" to start installation

🔧 Service management:
   Start:   systemctl start homelab-web-config
   Stop:    systemctl stop homelab-web-config
   Status:  systemctl status homelab-web-config
   Logs:    journalctl -u homelab-web-config -f

💡 The web interface will guide you through:
   • Setting admin passwords
   • Selecting services to deploy
   • Configuring network settings
   • Setting storage sizes
   • Live deployment tracking

📚 Once deployment completes, you'll have:
   • K3s Kubernetes cluster
   • Longhorn distributed storage
   • MetalLB load balancer
   • Portainer container management
   • Private Docker registry
   • Service discovery with Kubelish

EOF
echo -e "${NC}"

echo -e "${BLUE}🎊 Ready for configuration! Open http://${HOST_IP}:8080 in your browser.${NC}"