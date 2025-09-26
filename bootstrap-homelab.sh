#!/bin/bash
set -e

# Home Lab Bootstrap Script
# This script sets up the web configuration interface for your homelab

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting Home Lab Bootstrap (Stage 1)"
echo "========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   echo "Usage: sudo ./bootstrap-homelab.sh"
   exit 1
fi

# Ensure required system packages are installed
echo "📦 Installing system dependencies..."
apt-get update
apt-get install -y python3 python3-venv python3-pip

# Create homelab directory structure
echo "📁 Creating /opt/homelab directory..."
mkdir -p /opt/homelab

# Set up Python virtual environment for Ansible
VENV_PATH="/opt/homelab/venv"
if [ ! -d "$VENV_PATH" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

# Activate virtual environment and install Ansible
echo "📦 Installing Ansible in virtual environment..."
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
pip install ansible

# Add venv to PATH for this script
export PATH="$VENV_PATH/bin:$PATH"

# Change to ansible directory
cd "${SCRIPT_DIR}/ansible"

echo "🔧 Running Stage 1: Web Configuration Setup..."
echo "This will:"
echo "  • Install system dependencies"
echo "  • Create homelab user with sudo privileges"
echo "  • Copy project files to /opt/homelab"
echo "  • Build and start web configuration interface"
echo ""

# Run the websetup playbook
if ansible-playbook -i inventory/hosts.yml websetup.yml; then
    echo ""
    echo "✅ Stage 1 Complete!"
    echo "===================="
    echo ""

    # Get the IP address
    HOST_IP=$(hostname -I | awk '{print $1}')
    echo "🌐 Web configuration interface is ready at:"
    echo "   http://${HOST_IP}:8080"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Open your web browser and visit the URL above"
    echo "   2. Configure your homelab settings (network, services, passwords)"
    echo "   3. Click 'Deploy Now' to start Stage 2 (full deployment)"
    echo ""
    echo "📁 All project files are now located in: /opt/homelab"
    echo "🔐 The 'homelab' user has been created with full sudo privileges"
    echo ""
    echo "🎉 Ready for configuration!"
else
    echo ""
    echo "❌ Stage 1 failed!"
    echo "Check the output above for errors."
    echo "You may need to run: sudo ./bootstrap-homelab.sh"
    exit 1
fi