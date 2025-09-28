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
  gnupg \
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

echo "   Installing OpenTofu"
# Check if OpenTofu is installed
if command -v tofu &> /dev/null; then
    echo "OpenTofu is already installed."
    tofu --version
else
  # Dependencies
  apt-get install -y curl gnupg software-properties-common

  # Get installer
  curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

  # Make it executable and run it
  chmod +x install-opentofu.sh

  ./install-opentofu.sh --install-method deb

  # Clean up
  rm install-opentofu.sh
fi

# Verify installation
if command -v tofu &> /dev/null; then
    echo "OpenTofu has been successfully installed!"
    tofu --version
else
    echo "Installation failed. Please check the error messages above."
    exit 1
fi

# Create homelab user and group
echo "👤 Creating homelab user..."
if ! id "homelab" &>/dev/null; then
    useradd -m -s /bin/bash -d /home/homelab homelab
    usermod -aG sudo homelab

    # Create sudoers file for homelab user
    cat > /etc/sudoers.d/homelab << 'EOF'
# Allow homelab user to run all commands without password
homelab ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 440 /etc/sudoers.d/homelab

    # Validate sudoers file
    visudo -cf /etc/sudoers.d/homelab

fi

# Delete old working directories
echo "Cleaning up working directories..."

rm -rf ${INSTALL_DIR}
mkdir -p ${INSTALL_DIR}

cd ${INSTALL_DIR}

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


# Set proper ownership and permissions for homelab user
echo "🔐 Setting permissions for homelab user..."
chown -R homelab:homelab ${INSTALL_DIR}
chmod -R 755 ${INSTALL_DIR}
chmod g+s ${INSTALL_DIR}

# Create persistent OpenTofu state directory
echo "📁 Creating persistent OpenTofu state directory..."
mkdir -p /home/homelab/tfstate
chown homelab:homelab /home/homelab/tfstate
chmod 755 /home/homelab/tfstate

# Migrate existing state file if it exists
if [ -f "${INSTALL_DIR}/terraform/terraform.tfstate" ]; then
    echo "📋 Migrating existing OpenTofu state file..."
    cp "${INSTALL_DIR}/terraform/terraform.tfstate" /home/homelab/tfstate/terraform.tfstate
    chown homelab:homelab /home/homelab/tfstate/terraform.tfstate
fi

# Add venv to PATH for this script
export PATH="$VENV_PATH/bin:$PATH"

# Change to ansible directory
cd "${INSTALL_DIR}/ansible"

echo "🔧 Running Stage 1: Web Configuration Setup..."
echo "This will:"
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
    echo "📁 All project files are now located in: ${INSTALL_DIR}"
    echo "🔐 The 'homelab' user has been created with full sudo privileges"
    echo ""
    echo "🎉 Ready for configuration!"
else
    echo ""
    echo "❌ Stage 1 failed!"
    echo "Check the output above for errors."
    exit 1
fi