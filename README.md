# 🏠 Home Lab Pi

Turn your Raspberry Pi into a complete Kubernetes home lab with container registry, management UI, and Infrastructure as Code.

## ✨ Features

- **K3s Kubernetes cluster** - Lightweight Kubernetes perfect for ARM64
- **Container registry** - Local Docker registry for your images  
- **Portainer** - Web-based container management
- **Registry UI** - Browse and manage container images
- **Terraform automation** - Infrastructure as Code deployment
- **Security focused** - Dedicated service user with minimal privileges

## 🚀 Quick Start

### Prerequisites

- 64-Bit Raspberry Pi OS installation
- Internet connection
- SSH access

### System preparation
- Append cgroup_memory=1 cgroup_enable=memory to the existing line of parameters in the /boot/firmware/cmdline.txt

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/homelab-pi.git
   cd homelab-pi
   ```

2. **Run the setup script:**
   ```bash
   sudo ./setup.sh
   ```
   
   The script will automatically detect that you're running from the git repository and copy it to the homelab user's directory.

3. **Access your services:**
   - **Portainer:** http://your-pi-ip:32090
   - **Registry UI:** http://your-pi-ip:32080
   - **Registry API:** http://your-pi-ip:5000

That's it! 🎉

## 📖 Documentation

- [Installation Guide](docs/INSTALL.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Customization](docs/CUSTOMIZATION.md)

## 🔧 Management

### Service User

All services run under the `homelab` user for security:

```bash
# Switch to homelab user
sudo -u homelab -i

# Check service status
kubectl get pods
terraform status
```

### Service Management

```bash
# Registry service
sudo systemctl status docker-registry
sudo systemctl restart docker-registry

# View logs
journalctl -u docker-registry -f
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Registry      │    │   Registry UI   │
│   (Port 5000    │    │   (Port 32080)  │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │
          ┌─────────────────────┐
          │     K3s Cluster     │
          │   (Kubernetes)      │
          └─────────┬───────────┘
                    │
          ┌─────────────────────┐
          │  Portainer          │
          │   (Port 33090)      │
          └─────────────────────┘
```

## 🎯 What You Get

After installation, you'll have:

- **Local container registry** for storing your images
- **Kubernetes cluster** for container orchestration  
- **Web management interfaces** for easy administration
- **Infrastructure as Code** with Terraform
- **Secure setup** with dedicated service user
- **Remote access** capabilities for development

## 🔄 Updates

To update your homelab:

```bash
# Switch to homelab user
sudo -u homelab -i

# Pull latest changes
cd ~/homelab-pi
git pull

# Apply updates
cd terraform
terraform plan
terraform apply
```

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.
