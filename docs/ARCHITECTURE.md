# Home Lab Pi Architecture

This document describes the complete technical architecture and execution flow of the Home Lab Pi setup system, from initial user invocation through final service deployment.

## Overview

The Home Lab Pi system implements a **layered security model** with **Infrastructure as Code** principles to deploy a complete Kubernetes-based home lab environment. The system separates concerns between **privileged system setup** (root operations) and **application deployment** (service user operations).

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           User Space                           │
├─────────────────────────────────────────────────────────────────┤
│  Web Interfaces: Portainer (32090) | Registry UI (32080)       │
├─────────────────────────────────────────────────────────────────┤
│              Kubernetes Layer (K3s)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │  Portainer  │  │ Registry UI │  │   Traefik   │            │
│  │    Pod      │  │     Pod     │  │   Ingress   │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│           │               │               │                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ Longhorn PV │  │  NodePort   │  │   Service   │            │
│  │   Storage   │  │  Services   │  │    Mesh     │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
├─────────────────────────────────────────────────────────────────┤
│                        System Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Docker    │  │ Docker Reg  │  │   Systemd   │            │
│  │   Engine    │  │ (Port 5000) │  │  Services   │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
├─────────────────────────────────────────────────────────────────┤
│                    Operating System                            │
│           Raspberry Pi OS (64-bit) + Dependencies             │
└─────────────────────────────────────────────────────────────────┘
```

## Execution Flow

When a user runs `sudo ./setup.sh`, the following sequential process executes:

### Phase 1: System Initialization (Root Context)

#### Script: `setup.sh` (Entry Point)
**Location:** `/path/to/repo/setup.sh`  
**Context:** Root/sudo  
**Purpose:** Orchestrates the entire setup process

**Key Functions:**
1. **Security Validation**
   - Verifies root/sudo execution
   - Identifies real user (handles sudo context)
   - Prompts for confirmation before proceeding

2. **Repository Management** 
   - Detects if running from git repository (`.git/config` check)
   - **If in git repo:** Copies entire repository to `/home/homelab/homelab-pi/`
   - **If not in git repo:** Clones from `REPO_URL` to homelab directory
   - Sets proper ownership (`homelab:homelab`)

3. **System Preparation**
   - Updates system packages (`apt-get update && upgrade`)
   - Calls dependency installation script
   - Creates service user and security context

#### Script: `scripts/install-dependencies.sh`
**Context:** Root  
**Purpose:** Install and configure all system-level dependencies

**Dependencies Installed:**
1. **System Packages:**
   ```bash
   curl, wget, git, unzip, apt-transport-https, ca-certificates, 
   gnupg, lsb-release, software-properties-common, open-iscsi
   ```

2. **Container Runtime:** Docker CE
   - Downloads official Docker installation script
   - Enables and starts Docker daemon
   - Configures for system startup

3. **Kubernetes Distribution:** K3s
   - Lightweight Kubernetes for ARM64
   - Automatically configures kubeconfig
   - Sets appropriate permissions (chmod 644)

4. **Storage System:** Longhorn via Helm
   - Installs Helm package manager
   - Adds Longhorn repository
   - Deploys Longhorn for distributed storage
   - Enables iSCSI for block storage support

5. **Infrastructure as Code:** Terraform
   - Downloads ARM64 binary (version 1.6.6)
   - Installs to system PATH

**Why These Dependencies:**
- **Docker:** Container runtime for registry and development
- **K3s:** Lightweight Kubernetes perfect for ARM64/Pi
- **Longhorn:** Provides persistent storage with replication
- **Terraform:** Infrastructure as Code for reproducible deployments

#### Script: `scripts/create-user.sh`
**Context:** Root  
**Purpose:** Create dedicated service user with minimal privileges

**Security Implementation:**
1. **User Creation:**
   ```bash
   useradd -m -s /bin/bash homelab
   usermod -aG docker homelab  # Container access
   ```

2. **Directory Structure:**
   ```
   /home/homelab/
   ├── .kube/          # Kubernetes configuration
   ├── logs/           # Application logs  
   ├── data/           # Persistent data
   └── homelab-pi/     # Repository clone
   ```

3. **Sudoers Configuration (`/etc/sudoers.d/homelab`):**
   ```bash
   # Limited service management permissions
   homelab ALL=(ALL) NOPASSWD: /bin/systemctl {start,stop,restart,status} docker-registry
   homelab ALL=(ALL) NOPASSWD: /bin/journalctl -u docker-registry*
   homelab ALL=(ALL) NOPASSWD: /usr/local/bin/k3s ctr images*
   
   # Allow admin user to switch contexts
   ${ADMIN_USER} ALL=(homelab) NOPASSWD: ALL
   ```

4. **Environment Configuration:**
   - Custom `.bashrc` with kubectl/terraform aliases
   - KUBECONFIG environment variable
   - Status display on login
   - Auto-navigation to homelab directory

**Security Rationale:**
- **Principle of Least Privilege:** homelab user can only manage specific services
- **Isolation:** Application services run under dedicated user context
- **Auditability:** All homelab actions are traceable to service user

#### Script: `scripts/configure-services.sh`
**Context:** Root  
**Purpose:** Configure external services that run outside Kubernetes

**External Services Setup:**

1. **Docker Registry Service:**
   ```bash
   # Creates systemd service: /etc/systemd/system/docker-registry.service
   # Runs on port 5000 with persistent storage at /opt/registry/data
   # Enables image deletion for development workflows
   ```

2. **K3s Registry Integration:**
   ```yaml
   # /etc/rancher/k3s/registries.yaml
   mirrors:
     \"localhost:5000\":
       endpoint: [\"http://localhost:5000\"]
   configs:
     \"localhost:5000\":
       tls:
         insecure_skip_verify: true
   ```

3. **Service Pre-provisioning:**
   ```bash
   docker pull registry:2.8  # Avoids bootstrap dependency issues
   ```

**Why External Registry:**
- **Bootstrap Independence:** Registry available before Kubernetes services
- **Performance:** Direct host networking, no overlay network overhead
- **Simplicity:** Standard Docker registry, widely compatible
- **Reliability:** Survives Kubernetes cluster restarts

#### Kubeconfig Setup
**Context:** Root  
**Purpose:** Securely provide Kubernetes access to service user

```bash
# Copy K3s config with proper ownership
cp /etc/rancher/k3s/k3s.yaml /home/homelab/.kube/config
chown homelab:homelab /home/homelab/.kube/config
chmod 600 /home/homelab/.kube/config
```

**Security Notes:**
- Original `/etc/rancher/k3s/k3s.yaml` remains root-owned
- homelab user receives properly-owned copy
- Prevents permission denied errors during Terraform execution

### Phase 2: Application Deployment (Service User Context)

#### Script: `scripts/homelab-deploy.sh`
**Context:** homelab user (via `sudo -u homelab -i`)  
**Purpose:** Deploy Kubernetes applications using Infrastructure as Code

**Execution Flow:**

1. **Context Validation:**
   ```bash
   # Verify running as homelab user
   [ \"$(whoami)\" = \"homelab\" ] || exit 1
   
   # Verify kubeconfig accessibility
   [ -f \"$HOME/.kube/config\" ] || exit 1
   ```

2. **Kubernetes Readiness Check:**
   ```bash
   # Wait up to 150 seconds for K3s cluster readiness
   while ! kubectl get nodes >/dev/null 2>&1; do
     sleep 5
     ((RETRY_COUNT++))
     [ $RETRY_COUNT -lt 30 ] || exit 1
   done
   ```

3. **Configuration Generation:**
   ```bash
   # Create terraform.tfvars from template if not exists
   if [ ! -f \"terraform.tfvars\" ]; then
     cp terraform.tfvars.example terraform.tfvars
     sed -i \"s/192.168.1.100/${HOST_IP}/g\" terraform.tfvars
     sed -i \"s|/path/to/kubeconfig|${HOME}/.kube/config|g\" terraform.tfvars
   fi
   ```

4. **Infrastructure Deployment:**
   ```bash
   # Initialize Terraform state
   terraform init
   
   # Generate execution plan
   terraform plan
   
   # Apply infrastructure configuration
   terraform apply -auto-approve
   ```

#### Terraform Infrastructure Definition

**File:** `terraform/main.tf`  
**Purpose:** Declarative infrastructure specification

**Resource Deployment Order:**

1. **Registry UI Deployment:**
   ```hcl
   # Connects to external registry on port 5000
   # Provides web interface for image management
   # Enables image deletion for development workflows
   ```

2. **Portainer Storage (PVC):**
   ```hcl
   # Storage class: \"longhorn\" (distributed storage)
   # Access mode: ReadWriteOnce (single-pod attachment)
   # Capacity: 200Mi (sufficient for configuration data)
   ```

3. **Portainer RBAC:**
   ```hcl
   # Service account: portainer-sa
   # Cluster role binding: cluster-admin (full Kubernetes access)
   # Enables Portainer to manage entire cluster
   ```

4. **Portainer Deployment:**
   ```hcl
   # Image: portainer/portainer-ce:latest
   # Persistent volume mount: /data
   # Security context: root (required for Docker socket access)
   ```

5. **Service Exposure:**
   ```hcl
   # NodePort services for external access
   # Port mapping: 32090 (HTTP), 32443 (HTTPS)
   # Registry UI: 32080
   ```

6. **Ingress Configuration:**
   ```hcl
   # Traefik ingress controller (included with K3s)
   # DNS-based routing: portainer.local, registry.local
   # HTTP termination and routing
   ```

### Phase 3: Service Enablement (Root Context)

#### Final Service Configuration
**Context:** Root (return from homelab user)  
**Purpose:** Enable persistent services and provide user guidance

**Service Enablement:**
```bash
systemctl enable docker-registry    # Auto-start registry on boot
systemctl enable homelab-init       # Auto-deploy on system restart  
systemctl start docker-registry     # Start registry immediately
```

**User Guidance Output:**
- Service access URLs with dynamic IP detection
- Management commands and contexts
- Next steps for initial configuration

## Security Model

### Privilege Separation

1. **Root Operations (Setup Phase):**
   - System package installation
   - User creation and permission assignment
   - Service file creation and enablement
   - Kubeconfig copying with proper ownership

2. **Service User Operations (Deployment Phase):**
   - Terraform execution and state management
   - Kubernetes resource deployment
   - Application configuration and secrets management

3. **Runtime Operations:**
   - Container orchestration (K3s)
   - Application services (homelab user context)
   - External services (systemd management)

### Data Flow Security

```
Internet ─→ Router ─→ Pi Host ─→ Docker Bridge ─→ K3s Overlay ─→ Pods
                           │
                           └─→ Registry (Port 5000)
                           └─→ NodePort Services (32XXX)
```

### Storage Security

1. **Host Storage:** `/opt/registry/data` (root-owned, Docker access)
2. **User Storage:** `/home/homelab/` (homelab-owned)
3. **Kubernetes Storage:** Longhorn PVs (distributed, encrypted-capable)

## Component Interactions

### Bootstrap Dependencies

```
System Packages → Docker → K3s → Longhorn → Terraform → K8s Resources
     ↓              ↓       ↓        ↓         ↓           ↓
Base Tools → Container → K8s API → Storage → IaC → Application Layer
```

### Runtime Dependencies

```
Docker Registry ←→ K3s Registry Config
     ↕                    ↕
Registry UI ←────→ Kubernetes Service Mesh
     ↕                    ↕  
Portainer ←─────→ Kubernetes API Server
```

### Data Persistence

1. **Registry Data:** Host filesystem (`/opt/registry/data`)
2. **Portainer Data:** Longhorn PV (`longhorn` storage class)
3. **Configuration:** Git repository (`/home/homelab/homelab-pi`)
4. **State:** Terraform state (local backend)

## Error Handling and Recovery

### Validation Points

1. **Pre-flight Checks:**
   - Root privilege verification
   - Network connectivity testing
   - Disk space validation

2. **Component Readiness:**
   - Docker daemon status
   - K3s cluster health
   - Longhorn storage availability

3. **Deployment Validation:**
   - Terraform plan verification
   - Resource creation confirmation
   - Service accessibility testing

### Recovery Mechanisms

1. **Idempotent Operations:** All scripts handle re-execution
2. **Service Dependencies:** Systemd manages service ordering
3. **State Management:** Terraform tracks infrastructure state
4. **Health Monitoring:** Built-in readiness and liveness checks

## Monitoring and Observability

### System Level

- **Systemd Services:** `journalctl -u service-name`
- **Container Runtime:** `docker logs container-name`
- **Kubernetes Events:** `kubectl get events`

### Application Level

- **Portainer:** Built-in monitoring dashboard
- **Registry:** Health endpoint (`/v2/_catalog`)
- **Storage:** Longhorn web interface

### Log Aggregation

```
Application Logs → Container stdout → K8s API → kubectl logs
System Logs → Systemd Journal → journalctl
Service Logs → Docker logs → Registry access logs
```

This architecture provides a **secure**, **maintainable**, and **observable** home lab environment with clear separation of concerns and comprehensive automation.
