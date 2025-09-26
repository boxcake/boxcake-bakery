# Home Lab Web Configuration Interface

A user-friendly web interface for configuring and deploying your Kubernetes home lab infrastructure.

## Features

- **Interactive Configuration Wizard**: Step-by-step setup with real-time validation
- **Service Selection**: Choose which services to deploy (Portainer, Registry, Registry UI, Kubelish)
- **Network Configuration**: Customize Kubernetes networking and LoadBalancer pools
- **Storage Management**: Configure persistent storage sizes for services
- **Live Deployment Tracking**: Real-time logs and progress monitoring
- **Automatic Generation**: Creates Ansible and Terraform configuration files

## Quick Start

1. **Run the setup script:**
   ```bash
   sudo ./setup-with-web-config.sh
   ```

2. **Open the web interface:**
   - Visit `http://your-pi-ip:8080` in your browser

3. **Follow the wizard:**
   - Set admin password
   - Select services to deploy
   - Configure network settings
   - Set storage sizes
   - Review and deploy

## Architecture

### Backend (FastAPI)
- **Location**: `web-config/backend/`
- **Port**: 8080
- **Features**:
  - Configuration validation API
  - File generation (Ansible vars, Terraform tfvars)
  - Deployment management
  - Real-time progress tracking

### Frontend (React)
- **Location**: `web-config/frontend/`
- **Build Output**: `web-config/build/`
- **Features**:
  - Multi-step configuration wizard
  - Real-time validation
  - Progress tracking
  - Service status monitoring

## Development

### Backend Development
```bash
cd web-config/backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

### Frontend Development
```bash
cd web-config/frontend
npm install
npm run dev
```

### Building for Production
```bash
cd web-config/frontend
npm run build
# Built files will be in ../build/
```

## Configuration Files Generated

The web interface generates the following configuration files:

1. **`configs/user-config.yaml`** - Master configuration file
2. **`configs/network-defaults.yaml`** - Network configuration
3. **`ansible/vars/user-overrides.yml`** - Ansible variable overrides
4. **`terraform/user.tfvars`** - Terraform variable values

## Service Management

The web configuration service runs as a systemd service:

```bash
# Control the service
systemctl start homelab-web-config
systemctl stop homelab-web-config
systemctl restart homelab-web-config

# View logs
journalctl -u homelab-web-config -f

# Check status
systemctl status homelab-web-config
```

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/config/defaults` - Get default configuration
- `POST /api/config/validate` - Validate configuration
- `POST /api/config/save` - Save configuration and generate files
- `POST /api/deployment/start` - Start deployment
- `GET /api/deployment/status/{id}` - Get deployment status
- `WebSocket /ws/deployment` - Real-time deployment logs

## Troubleshooting

### Service Won't Start
```bash
# Check service status
systemctl status homelab-web-config

# View detailed logs
journalctl -u homelab-web-config -n 50

# Check if port is in use
netstat -tlpn | grep 8080
```

### Frontend Not Loading
```bash
# Rebuild frontend
cd web-config/frontend
npm run build

# Restart service
systemctl restart homelab-web-config
```

### Configuration Not Applied
- Check that generated files exist in `configs/` and `ansible/vars/`
- Verify Ansible playbook includes `vars/user-overrides.yml`
- Check Terraform is using `user.tfvars` file

## Security Considerations

- The web interface runs on port 8080 without authentication
- It's designed for initial setup on a local network
- The service should be stopped after initial configuration
- Generated configuration files may contain sensitive information

## Integration with Existing Setup

The web interface integrates with the existing Ansible/Terraform setup:

1. **Ansible Integration**: Generates `vars/user-overrides.yml` with user settings
2. **Terraform Integration**: Creates `user.tfvars` with service configuration
3. **Network Integration**: Updates `configs/network-defaults.yaml` with custom CIDRs
4. **Service Selection**: Uses conditional deployment in Terraform modules