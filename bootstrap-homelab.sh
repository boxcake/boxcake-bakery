#!/bin/bash
set -e

# Home Lab Bootstrap Script
# This script sets up the web configuration interface for your homelab

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/homelab"

echo "🚀 Starting Home Lab Bootstrap (Stage 1)"
echo "========================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   echo "Usage: sudo ./bootstrap-homelab.sh"
   exit 1
fi

# TODO:
#  Prompt user if the /opt/homelab directory already exists
#  y/n to deleting the contents of the install directory - exit if n

# Ensure required system packages are installed
echo "📦 Installing system dependencies..."
apt-get update
apt-get install -y \
  curl \
  git \
  rsync \
  python3 \
  python3-venv \
  python3-pip \
  software-properties-common \
  open-iscsi \
  python3-pip \
  python3-venv \
  python3-dev \
  python3-setuptools \
  python3-kubernetes \
  python3-yaml \
  python3-jsonpatch \
  jq \
  tree \
  htop \
  docker \
  docker-compose \
  avahi-daemon \
  libnss-mdns


# Create homelab user and group
echo "👤 Creating homelab user..."
if ! id "homelab" &>/dev/null; then
    useradd -m -s /bin/bash -d /opt/homelab homelab
    usermod -aG sudo homelab

    # Create sudoers file for homelab user
    cat > /etc/sudoers.d/homelab << 'EOF'
# Allow homelab user to run all commands without password
homelab ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 440 /etc/sudoers.d/homelab

    # Validate sudoers file
    visudo -cf /etc/sudoers.d/homelab

# TODO: else  - we need to verify that the existing home dir for the homelab user is our install_dir and use usermod if its not
fi

# Delete old working directories
cd ${INSTALL_DIR} && rm -rf ${INSTALL_DIR}/* || exit

# Shallow clone the repo into the install directory
git clone --depth 1 https://github.com/boxcake/boxcake-bakery.git ./

# Set up Python virtual environment for Ansible
VENV_PATH="${INSTALL_DIR}/venv"

if [ ! -d "$VENV_PATH" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

# Activate virtual environment and install Ansible
echo "📦 Installing Ansible in virtual environment..."
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
pip install ansible

exit

# Set proper ownership and permissions for homelab user
echo "🔐 Setting permissions for homelab user..."
chown -R homelab:homelab /opt/homelab
chmod -R 755 /opt/homelab

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