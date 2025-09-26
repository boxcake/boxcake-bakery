#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner
echo -e "${BLUE}"
cat << 'EOF'
🏠 Boxcake Bakery - Home Lab Bootstrap
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Stage 1: System Bootstrap
• Create homelab user with proper permissions
• Install essential dependencies
• Set up web configuration interface
• Prepare for user-driven configuration

EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Stage 1 bootstrap must be run as root${NC}"
    echo -e "${YELLOW}💡 Usage: sudo ./bootstrap-homelab.sh${NC}"
    exit 1
fi

# Get the real user (in case running with sudo)
REAL_USER="${SUDO_USER:-$USER}"
if [ "$REAL_USER" = "root" ]; then
    echo -e "${YELLOW}⚠️  Running as root. This will create a 'homelab' user for management.${NC}"
    REAL_USER="homelab"
fi

# Copy project to /opt/homelab first (as root)
echo -e "${YELLOW}📁 Setting up project directory...${NC}"
mkdir -p /opt/homelab
cp -r "${SCRIPT_DIR}"/* /opt/homelab/ 2>/dev/null || true
cp -r "${SCRIPT_DIR}"/.[^.]* /opt/homelab/ 2>/dev/null || true

# Remove unnecessary directories
rm -rf /opt/homelab/.git /opt/homelab/web-config/frontend/node_modules /opt/homelab/web-config/backend/venv /opt/homelab/web-config/build 2>/dev/null || true

echo -e "${GREEN}🚀 Starting Home Lab Bootstrap (Stage 1)...${NC}"
echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "  Project directory: /opt/homelab"
echo -e "  Management user: homelab"
echo -e "  Original user: ${REAL_USER}"
echo ""

# Confirm before proceeding
read -p "Continue with bootstrap? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Bootstrap cancelled${NC}"
    exit 0
fi

# Check if Ansible is available
if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo -e "${YELLOW}📦 Installing Ansible...${NC}"
    apt-get update -qq
    apt-get install -y python3 python3-pip
    python3 -m pip install --break-system-packages ansible

    echo -e "${GREEN}✅ Ansible installed${NC}"
fi

# Set ownership of project directory
chown -R root:root /opt/homelab

# Run Stage 1 bootstrap playbook
echo -e "${YELLOW}🎭 Running Stage 1 bootstrap playbook...${NC}"

cd "/opt/homelab"

# Create minimal inventory for localhost
mkdir -p ansible/inventory
cat > ansible/inventory/bootstrap-hosts.yml << EOF
---
bootstrap:
  hosts:
    localhost:
      ansible_connection: local
      ansible_become: yes
      admin_user: "${REAL_USER}"
EOF

# Run the bootstrap playbook
ansible-playbook \
    -i ansible/inventory/bootstrap-hosts.yml \
    -e "admin_user=${REAL_USER}" \
    ansible/stage1-bootstrap.yml

if [ $? -eq 0 ]; then
    HOST_IP=$(hostname -I | awk '{print $1}')

    echo -e "${GREEN}"
    cat << EOF

🎉 Stage 1 Bootstrap Complete!

✅ System prepared:
   • Homelab user created with sudo permissions
   • Essential packages installed
   • Ansible configured
   • Web configuration service running

🌐 Next Steps:
   1. Access the web interface: http://${HOST_IP}:8080
   2. Complete the configuration wizard
   3. Click "Deploy Now" for Stage 2 deployment

👤 Management user: homelab
🏠 Project location: /opt/homelab/

📱 The web interface will guide you through:
   • Setting admin passwords
   • Selecting services to deploy
   • Configuring network settings
   • Managing storage allocations
   • Live deployment monitoring

🚀 Stage 2 will run as homelab user and:
   • Deploy K3s Kubernetes cluster
   • Set up Longhorn distributed storage
   • Install MetalLB load balancer
   • Deploy selected services (Portainer, Registry, etc.)
   • Configure service discovery

🔐 The homelab user has full sudo permissions for system management.

EOF
    echo -e "${NC}"

    echo -e "${BLUE}🎊 Bootstrap complete! Visit http://${HOST_IP}:8080 to continue.${NC}"
else
    echo -e "${RED}❌ Bootstrap failed${NC}"
    echo -e "${YELLOW}💡 Check the output above for error details${NC}"
    exit 1
fi