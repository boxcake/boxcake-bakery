# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a complete home software development lab automation system that uses Ansible + OpenTofu to deploy Kubernetes infrastructure on Raspberry Pi systems. The architecture follows a three-phase deployment pattern:

1. **Deploy web-app (Shell+Ansible)**: Deploys a lightweight webapp which is used to collect configuration information
2. **Infrastructure Phase (Ansible)**: Deploys K3s Kubernetes, Docker, networking, storage, and base services
3. **Application Phase (OpenTofu)**: Deploys containerized applications and services on the Kubernetes cluster

### Key Components

**Ansible Infrastructure (`ansible/`):**
- First playbook: `ansible/websetup.yml`
- Deploys a web service with configuration wizard
- Second playbook: `ansible\stage2-deploy.yml`
- Deploys K3s single-node Kubernetes cluster with Longhorn storage
- Configures MetalLB load balancer with IP address pools
- Sets up Kubelish for mDNS service discovery
- Automatically runs OpenTofu deployment
- Autoconfigures Portainer with admin credentials and local registry

**OpenTofu/Terraform (`terraform/`):**
- Kubernetes-native resource definitions
- Deploys Portainer (container UI), Docker Registry, and Registry UI
- Uses LoadBalancer services with MetalLB for external access
- Leverages persistent volumes with Longhorn storage class

**Configuration Management:**
- Network settings: `ansible/vars/network.yml` and `configs/network-defaults.yaml`
- Main variables: `ansible/vars/main.yml`
- Registry configuration: `configs/registries.yaml`

## Common Commands

### Staged Web-Based Setup (Recommended)
```bash
# Stage 1: Bootstrap system and web interface
sudo bash ./bootstrap-homelab.sh

# Stage 2: Automatic via web interface after configuration
# Visit http://your-ip:8080 provide config data and click "Deploy Now"
```
Two-stage deployment with web-based configuration interface.

### Management Commands
```bash
# Check cluster status
kubectl get nodes,pods,svc -A

# View load balancer services
kubectl get svc -A | grep LoadBalancer

# Check Longhorn storage
kubectl get pv,pvc -A

# View service discovery
kubectl get svc -o json | jq '.items[] | select(.metadata.annotations."kubelish/service-name")'
```

### Troubleshooting
```bash
# OpenTofu state management
cd terraform/
tofu state list
tofu refresh

# Service debugging
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

## Key Architectural Patterns

### Service Discovery Integration
Services use Kubelish annotations for mDNS discovery:
```yaml
annotations:
  "kubelish/service-name" = "portainer"
  "kubelish/service-type" = "_portainerui._tcp"
  "kubelish/txt" = "Portainer container management UI"
```

### Storage Architecture
- Longhorn provides distributed storage across cluster nodes
- All applications use PersistentVolumes with `storage_class_name = "longhorn"`
- Master node deployment ensures registry runs on control plane

### Load Balancer Integration
- MetalLB provides LoadBalancer services with configurable IP pools
- Services annotated with `"metallb.io/address-pool" = var.metallb_pool_name`
- Automatic IP assignment from defined ranges

### Security Model
- Homelab group-based sudo permissions in `/etc/sudoers.d/homelab`
- Kubernetes service accounts with appropriate RBAC
- Registry runs with insecure flag for internal development use

## Important Configuration Files

- `ansible/vars/main.yml`: Core variables including passwords, versions, ports
- `ansible/vars/network.yml`: Network configuration and IP ranges
- `terraform/variables.tf`: OpenTofu input variables and defaults
- `configs/registries.yaml`: K3s registry configuration for insecure registries
- `ansible/inventory/hosts.yml`: Target host definitions

## Web Configuration Interface

The repository includes a modern web-based configuration system located in `web-config/`:

**Features:**
- Interactive configuration wizard with real-time validation
- Service selection (Portainer, Registry, Registry UI, Kubelish)
- Network CIDR customization with conflict detection
- Storage size configuration with validation
- Live deployment progress tracking
- Automatic generation of Ansible/Terraform configuration files

**Architecture:**
- **Backend**: FastAPI (Python) serving configuration API and static files
- **Frontend**: React SPA with step-by-step wizard interface
- **Integration**: Generates `ansible/vars/user-overrides.yml` and `terraform/user.tfvars`

**Generated Configuration Files:**
- `configs/user-config.yaml` - Master configuration
- `configs/network-defaults.yaml` - Network settings
- `ansible/vars/user-overrides.yml` - Ansible variable overrides
- `terraform/user.tfvars` - Terraform input variables

## Development Workflow

1. **Web Interface Changes**: Modify React components in `web-config/frontend/src/`
2. **Backend API Changes**: Update FastAPI endpoints in `web-config/backend/`
3. **Infrastructure Changes**: Modify Ansible roles for base system changes
4. **Application Changes**: Update OpenTofu resources for service deployments
5. **Testing**: Use `tofu plan` before applying, leverage tags for selective deployment
6. **Building**: Run `npm run build` in frontend directory for production builds

The system supports both web-based configuration and direct deployment modes. All deployments are idempotent - multiple runs are safe and will only make necessary changes.

