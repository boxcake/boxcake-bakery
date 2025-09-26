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

# Check if we have Ansible installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "📦 Installing Ansible..."
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible
fi

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