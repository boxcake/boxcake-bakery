#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the actual script directory (works with sudo)
if [ -n "${SUDO_USER}" ]; then
    # When run with sudo, get the original user's directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

# Debug: Show what we detected
echo -e "${YELLOW}🔍 Detected paths:${NC}"
echo -e "  Script directory: ${SCRIPT_DIR}"
echo -e "  Ansible directory: ${ANSIBLE_DIR}"
echo -e "  Current working directory: $(pwd)"
echo ""

# Banner
echo -e "${BLUE}"
cat << 'EOF'
🏠 Boxcake Bakery - Dev Lab Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Complete Kubernetes home lab with:
• K3s cluster
• Container registry  
• Registry UI
• Portainer management
• Ansible-powered deployment
EOF
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root or with sudo${NC}"
    echo -e "${YELLOW}💡 Usage: sudo ./setup-via-ansible.sh${NC}"
    exit 1
fi

# Get the real user (in case running with sudo)
REAL_USER="${SUDO_USER:-$USER}"
if [ "$REAL_USER" = "root" ]; then
    echo -e "${YELLOW}⚠️  Running as root. Enter the username that should have admin access:${NC}"
    read -p "Username: " REAL_USER
fi

echo -e "${GREEN}🚀 Starting Ansible-based Home Lab Pi setup...${NC}"
echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "  Admin user: ${REAL_USER}"
echo -e "  Ansible directory: ${ANSIBLE_DIR}"
echo -e "  Host: localhost"
echo ""

# Confirm before proceeding
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled${NC}"
    exit 0
fi

# Step 1: Install/Update Ansible if not present or outdated
echo -e "${YELLOW}📦 Checking Ansible installation...${NC}"

# Check current Ansible version
if command -v ansible-playbook >/dev/null 2>&1; then
    CURRENT_VERSION=$(ansible --version | head -1 | awk '{print $3}' | cut -d'[' -f1)
    echo -e "${GREEN}✅ Ansible installed: $CURRENT_VERSION${NC}"
    
    # Check if version is older than 2.15
    if [ "$(echo "$CURRENT_VERSION 2.15.0" | tr " " "\n" | sort -V | head -n1)" = "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" != "2.15.0" ]; then
        echo -e "${YELLOW}⚠️  Ansible version $CURRENT_VERSION is outdated (collections require 2.15+)${NC}"
        echo -e "${YELLOW}🔄 Updating Ansible...${NC}"
        
        # Remove old ansible
        apt-get remove -y ansible
        
        # Install latest ansible via pip with system packages override
        python3 -m pip install --break-system-packages ansible
        
        echo -e "${GREEN}✅ Ansible updated to latest version${NC}"
        ansible --version | head -1
    fi
else
    echo -e "${YELLOW}🔧 Installing latest Ansible...${NC}"
    
    # Install Python and pip first
    apt-get install -y python3 python3-pip
    
    # Install latest ansible
    python3 -m pip install --break-system-packages ansible
    
    echo -e "${GREEN}✅ Ansible installed${NC}"
    ansible --version | head -1
fi

# Step 1: Validate Ansible directory structure
echo -e "${YELLOW}📁 Validating Ansible setup...${NC}"

if [ ! -d "$ANSIBLE_DIR" ]; then
    echo -e "${RED}❌ Ansible directory not found: $ANSIBLE_DIR${NC}"
    exit 1
fi

if [ ! -f "$ANSIBLE_DIR/site.yml" ]; then
    echo -e "${RED}❌ Main playbook not found: $ANSIBLE_DIR/site.yml${NC}"
    echo -e "${YELLOW}💡 Run this script from the homelab-pi directory${NC}"
    exit 1
fi

# Step 2: Install required Ansible collections
echo -e "${YELLOW}📦 Installing required Ansible collections...${NC}"
if [ -f "$ANSIBLE_DIR/requirements.yml" ]; then
    ansible-galaxy collection install -r "$ANSIBLE_DIR/requirements.yml" --force
    echo -e "${GREEN}✅ Ansible collections installed${NC}"
else
    echo -e "${YELLOW}⚠️  No requirements.yml found, installing essential collections...${NC}"
    ansible-galaxy collection install kubernetes.core community.general --force
fi


# Step 3: Create dynamic inventory
echo -e "${YELLOW}⚙️  Preparing Ansible configuration...${NC}"

# Create temporary inventory file
cat > "$ANSIBLE_DIR/inventory/hosts.yml" << EOF
---
homelab:
  hosts:
    localhost:
      ansible_connection: local
      ansible_become: yes
      admin_user: "${REAL_USER}"
      homelab_user: "homelab"
      homelab_home: "/home/homelab"
EOF

echo -e "${GREEN}✅ Ansible configuration ready${NC}"

# Step 4: Run Ansible playbook
echo -e "${YELLOW}🎭 Running Ansible playbook...${NC}"

# Ensure we're in the right directory
if [ ! -d "$ANSIBLE_DIR" ]; then
    echo -e "${RED}❌ Ansible directory not found: $ANSIBLE_DIR${NC}"
    echo -e "${YELLOW}💡 Current directory: $(pwd)${NC}"
    echo -e "${YELLOW}💡 Script location: $SCRIPT_DIR${NC}"
    exit 1
fi

cd "$ANSIBLE_DIR"
echo -e "${GREEN}✅ Changed to Ansible directory: $(pwd)${NC}"

# Run the main playbook
ansible-playbook \
    -i inventory/hosts.yml \
    -e "admin_user=${REAL_USER}" \
    site.yml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Ansible playbook completed successfully${NC}"
else
    echo -e "${RED}❌ Ansible playbook failed${NC}"
    echo -e "${YELLOW}💡 Check the output above for error details${NC}"
    exit 1
fi

# Step 5: Final information
HOST_IP=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}"
cat << EOF
🎉 Home Lab Pi setup complete!

📋 Access URLs:
  Portainer:   http://${HOST_IP}:32090
  Registry UI: http://${HOST_IP}:32080  
  Registry:    http://${HOST_IP}:5000

🔧 Management:
  Service user: homelab
  Config path:  /home/homelab/homelab-pi
  
🖥️  Switch to homelab user:
  sudo -u homelab -i

📝 Next steps:
  1. Visit Portainer to create admin user
  2. Add to /etc/hosts: ${HOST_IP} registry.local portainer.local
  3. Test: curl http://${HOST_IP}:5000/v2/_catalog

📚 Documentation: /home/homelab/homelab-pi/docs/

🎭 Ansible logs: /var/log/ansible.log
EOF
echo -e "${NC}"
