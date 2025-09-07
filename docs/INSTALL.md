# Installation Guide

This guide provides detailed installation instructions for Home Lab Pi.

## Prerequisites

### Hardware Requirements

- **Raspberry Pi 4** (4GB RAM minimum, 8GB recommended)
- **MicroSD card** (32GB minimum, Class 10 or better)
- **Network connection** (Ethernet preferred for stability)
- **Power supply** (Official Raspberry Pi 4 power supply recommended)

### Software Requirements

- **Raspberry Pi OS** (64-bit, Lite or Desktop)
- **Fresh installation** (recommended for best results)

## Step-by-Step Installation

### 1. Prepare Raspberry Pi OS

1. **Download Raspberry Pi Imager:**
   - Visit [rpi.org](https://www.raspberrypi.org/software/)
   - Download and install Raspberry Pi Imager

2. **Flash OS to SD card:**
   - Insert MicroSD card
   - Open Raspberry Pi Imager
   - Choose "Raspberry Pi OS (64-bit)" - Lite version is sufficient
   - Select your SD card
   - Click the gear icon for advanced options:
     - ✅ Enable SSH
     - ✅ Set username and password
     - ✅ Configure WiFi (if needed)
   - Flash the image

3. **Boot and connect:**
   - Insert SD card into Pi
   - Connect Ethernet cable (recommended)
   - Power on the Pi
   - SSH into the Pi: `ssh username@pi-ip-address`

### 2. Run Home Lab Installation

1. **Update system (optional but recommended):**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/homelab-pi.git
   cd homelab-pi
   ```

3. **Run the installation script:**
   ```bash
   sudo ./setup.sh
   ```
   
   **Note:** The script automatically detects that you're running from the git repository and will:
   - Copy the repository to `/home/homelab/homelab-pi/`
   - Set up proper permissions for the homelab user
   - Continue with the installation process

4. **Follow the prompts:**
   - Confirm your admin username
   - Wait for installation to complete (10-15 minutes)

### 3. Verify Installation

1. **Check services are running:**
   ```bash
   # Check K3s
   sudo kubectl get nodes
   
   # Check Docker registry
   curl http://localhost:5000/v2/_catalog
   
   # Check pods
   sudo kubectl get pods
   ```

2. **Access web interfaces:**
   - **Portainer:** http://your-pi-ip:32090
   - **Registry UI:** http://your-pi-ip:32080

### 4. Initial Configuration

#### Portainer Setup

1. Navigate to http://your-pi-ip:32090
2. Create admin user on first visit
3. Choose "Get Started" to use local environment
4. Explore the Kubernetes environment

#### Registry Configuration

1. Navigate to http://your-pi-ip:32080
2. Browse the (initially empty) registry
3. Test pushing an image:
   ```bash
   # Pull a test image
   docker pull hello-world
   
   # Tag for local registry
   docker tag hello-world localhost:5000/hello-world
   
   # Push to local registry
   docker push localhost:5000/hello-world
   ```

## Post-Installation

### Set up Remote Access

To manage your homelab from your laptop:

1. **On the Raspberry Pi:**
   ```bash
   # Create remote kubeconfig
   sudo -u homelab -i
   sed 's/127.0.0.1/YOUR-PI-IP/g' ~/.kube/config > ~/k3s-remote.yaml
   ```

2. **On your laptop:**
   ```bash
   # Copy the config
   scp homelab@your-pi-ip:~/k3s-remote.yaml ~/.kube/k3s-homelab
   
   # Use it
   export KUBECONFIG=~/.kube/k3s-homelab
   kubectl get nodes
   ```

### Set up DNS (Optional)

Add entries to your `/etc/hosts` file for easier access:

```bash
echo "YOUR-PI-IP registry.local portainer.local" | sudo tee -a /etc/hosts
```

Then access via:
- http://portainer.local
- http://registry.local

## Troubleshooting

If you encounter issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## What's Next?

- [Customize your setup](CUSTOMIZATION.md)
- Add more services with Terraform
- Set up CI/CD pipelines
- Create your own container images
