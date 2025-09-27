# Home Lab Pi - Product Backlog

This document tracks feature requests, improvements, and technical debt for the Home Lab Pi project. Items are organized by priority and implementation complexity.

## 🚀 High Priority

### 1. OpenTofu Migration
**Epic:** Replace Terraform with OpenTofu for Infrastructure as Code

**Description:** 
Migrate from HashiCorp Terraform to the open-source OpenTofu fork to ensure long-term sustainability and avoid licensing concerns.

**Benefits:**
- Open source with community governance
- Terraform compatibility maintained
- No licensing restrictions for commercial use
- Active community development

**Implementation Tasks:**
- [ ] Research OpenTofu compatibility with current Terraform configurations
- [ ] Update `install-dependencies.sh` to install OpenTofu instead of Terraform
- [ ] Test all existing `.tf` files with OpenTofu
- [ ] Update documentation and references
- [ ] Create migration guide for existing deployments
- [ ] Update CI/CD pipelines (if applicable)

**Acceptance Criteria:**
- All current Terraform functionality works with OpenTofu
- Installation script downloads and installs OpenTofu
- Documentation updated to reflect change
- Backward compatibility maintained for existing deployments

**Estimated Effort:** Medium  
**Risk:** Low (high compatibility expected)

---

### 2. Home Lab Web Dashboard
**Epic:** Custom web interface for unified service management

**Description:**
Create a custom web dashboard accessible on standard HTTP/HTTPS ports (80/443) that serves as the primary entry point for home lab management.

**Features:**
- **Service Status Dashboard**
  - Real-time status of all services (K3s, Registry, Portainer, etc.)
  - Resource utilization (CPU, Memory, Storage)
  - Service health indicators and uptime metrics

- **Unified Service Access**
  - Proxy/embed Portainer interface
  - Proxy/embed Registry UI interface
  - Single sign-on integration
  - Reverse proxy to backend services

- **Configuration Management**
  - Basic home lab settings (hostnames, ports, etc.)
  - User management and authentication
  - Service enable/disable toggles
  - Configuration backup/restore

- **Home Lab Information**
  - System information (Pi model, OS version, uptime)
  - Network configuration and connectivity
  - Storage usage and health
  - Quick setup guides and documentation links

**Multiple IP Implementation Options:**

**Option 1: Linux IP Aliasing (Simple)**
```bash
# Add virtual IPs to Pi interface
sudo ip addr add 192.168.1.101/24 dev eth0 label eth0:portainer
sudo ip addr add 192.168.1.102/24 dev eth0 label eth0:gitea
sudo ip addr add 192.168.1.103/24 dev eth0 label eth0:registry

# Make persistent via /etc/netplan/ or /etc/network/interfaces
```

**Option 2: MetalLB Load Balancer (Kubernetes-native)**
```yaml
# MetalLB configuration for IP pool
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
  namespace: metallb-system
data:
  config: |
    address-pools:
    - name: homelab-pool
      protocol: layer2
      addresses:
      - 192.168.1.101-192.168.1.110
```

**Option 3: Keepalived + HAProxy (Advanced)**
- Virtual IP management with failover
- Load balancing across multiple Pis
- High availability for critical services

**mDNS Implementation:**
```bash
# Install Avahi on Pi
sudo apt-get install avahi-daemon avahi-utils

# Configure services in /etc/avahi/services/
# portainer.service:
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">Portainer on %h</name>
  <service>
    <type>_http._tcp</type>
    <port>80</port>
    <host-name>portainer.local</host-name>
  </service>
</service-group>
```

**Router Integration Strategies:**

**Zero-Config (mDNS Only):**
- No router changes required
- Works on Apple devices automatically
- Windows 10+ supports .local resolution
- Android requires Bonjour browser apps

**DHCP Reservation Method:**
```
# Reserve IP ranges in router DHCP
192.168.1.100-110 Reserved for "HomeLabPi"

# Pi requests specific IPs via DHCP
# Router assigns consistently
```

**Router DNS Override (Advanced Users):**
```
# For users comfortable with router config
# Add custom DNS entries pointing to Pi IPs
dashboard.home → 192.168.1.100
portainer.home → 192.168.1.101
gitea.home     → 192.168.1.102
```

**User Experience Comparison:**

**Current (NodePort):**
```
http://192.168.1.100:32090  # Portainer
http://192.168.1.100:32080  # Registry UI
http://192.168.1.100:5000   # Registry API
```

**With Multiple IPs + mDNS:**
```
http://dashboard.local      # Main dashboard
http://portainer.local      # Portainer
http://gitea.local          # Git server
http://registry.local       # Registry UI

# OR with IPs:
http://192.168.1.100        # Dashboard
http://192.168.1.101        # Portainer  
http://192.168.1.102        # Gitea
http://192.168.1.103        # Registry
```

**Technical Implementation:**
- [ ] Choose web framework (React/Vue.js frontend + Go/Node.js backend)
- [ ] Design responsive UI/UX for mobile and desktop access
- [ ] Implement reverse proxy for service integration
- [ ] Create REST API for system management
- [ ] Implement authentication system
- [ ] Add SSL/TLS termination and certificate management
- [ ] Integrate with Kubernetes API for real-time data
- [ ] Create configuration management backend

**Security Considerations:**
- [ ] Implement proper authentication and authorization
- [ ] Secure reverse proxy configuration
- [ ] Rate limiting and DDOS protection
- [ ] Secure configuration storage
- [ ] Audit logging for administrative actions

**Deployment Strategy:**
- [ ] Containerize web application
- [ ] Deploy as Kubernetes service
- [ ] Configure Traefik ingress for ports 80/443
- [ ] Implement health checks and monitoring
- [ ] Create backup and recovery procedures

**Acceptance Criteria:**
- Dashboard accessible on http://pi-ip and https://pi-ip
- All existing services accessible through dashboard
- Configuration changes persist across restarts
- Mobile-responsive design
- Secure authentication system
- Real-time status updates

**Estimated Effort:** Large  
**Risk:** Medium (complex integration requirements)

---

## 🔧 Medium Priority

### 3. Ansible-based Configuration Management
**Epic:** Replace bash scripts with Ansible for better configuration management

**Description:**
Migrate from bash scripts to Ansible playbooks for more robust, idempotent, and maintainable system configuration.

**Benefits:**
- Idempotent operations (safe to run multiple times)
- Better error handling and rollback capabilities
- Template-based configuration management
- Inventory management for multiple nodes
- Extensive module ecosystem
- Better testing and validation capabilities

**Implementation Scope:**
- [ ] Create Ansible inventory for single-node and multi-node setups
- [ ] Convert `install-dependencies.sh` to Ansible playbook
- [ ] Convert `create-user.sh` to Ansible user management tasks
- [ ] Convert `configure-services.sh` to Ansible service templates
- [ ] Template configuration files (registries.yaml, systemd services)
- [ ] Implement variable-driven configuration
- [ ] Add pre-flight checks and validation tasks
- [ ] Create deployment verification playbook

**Playbook Structure:**
```
ansible/
├── site.yml                    # Main playbook
├── inventory/
│   ├── hosts.yml              # Inventory file
│   └── group_vars/
├── roles/
│   ├── system-prep/           # System updates and packages
│   ├── docker/                # Docker installation and config
│   ├── k3s/                   # K3s cluster setup
│   ├── storage/               # Longhorn storage setup
│   ├── registry/              # Container registry setup
│   ├── homelab-user/          # Service user creation
│   └── applications/          # App deployment coordination
├── templates/                 # Jinja2 templates for configs
└── vars/                      # Variable definitions
```

**Migration Strategy:**
- [ ] Parallel development (maintain bash scripts during transition)
- [ ] Gradual migration by component
- [ ] Extensive testing on clean systems
- [ ] Documentation for both approaches initially
- [ ] Deprecation timeline for bash scripts

**Acceptance Criteria:**
- Ansible playbooks achieve same end state as bash scripts
- Playbooks are idempotent and can be run multiple times safely
- Support for both single-node and multi-node deployments
- Template-driven configuration with sensible defaults
- Comprehensive error handling and reporting
- Documentation includes Ansible requirements and usage

**Estimated Effort:** Large  
**Risk:** Medium (significant refactoring required)

---

## 🎨 Low Priority / Future Enhancements

### 4. DNS and Service Discovery Solution
**Epic:** Implement comprehensive DNS solution for service discovery and integration

**Description:**
With modular component selection, services need reliable ways to discover and communicate with each other. A proper DNS solution enables seamless integration between Gitea, Registry, Portainer, and future services.

**Service Discovery Challenges:**
- **Internal Communication:** Services need to find each other (Gitea → Registry, Dashboard → All Services)
- **User Access:** Consistent URLs regardless of enabled components
- **Configuration Complexity:** Hardcoded IPs/ports become unmanageable
- **SSL/TLS Certificates:** Automatic certificate generation for internal services
- **Load Balancing:** Distribute traffic when services scale

**Proposed Solutions:**

**Option A: CoreDNS + External DNS (Recommended)**
- **CoreDNS:** Enhanced K3s internal DNS with custom zones
- **External DNS:** Automatic DNS record management
- **cert-manager:** Automatic SSL certificate generation
- **Supports:** `.homelab`, `.local`, custom domain zones

**Option B: Pi-hole + Custom DNS**
- **Pi-hole:** Network-wide DNS with ad blocking
- **Custom DNS entries:** Manual service record management
- **Benefits:** Ad blocking + DNS resolution
- **Drawbacks:** Manual configuration overhead

**Option C: Multiple IP Addresses per Node (Recommended for Home Lab)**
- **Virtual IPs:** Assign multiple IP addresses to single Pi
- **Service-specific IPs:** Each major service gets its own IP:80/443
- **Benefits:** Clean URLs, standard ports, no router configuration
- **Implementation:** Linux IP aliasing or MetalLB load balancer

**Option D: mDNS/Avahi + Traefik (Zero-Config Solution)**
- **mDNS/Avahi:** Zero-configuration networking with .local domains
- **Automatic Discovery:** Services advertise themselves on local network
- **Benefits:** No router DNS changes, works out-of-the-box
- **Integration:** Modern devices automatically resolve .local addresses

**Hybrid Approach (Recommended):**
Combine multiple IPs with mDNS for optimal user experience:
```
192.168.1.100    # Main Pi IP - Dashboard
192.168.1.101    # Portainer service  
192.168.1.102    # Git service
192.168.1.103    # Registry service

AND

dashboard.local   # mDNS names
portainer.local
gitea.local
registry.local
```

**Technical Implementation:**
```yaml
# Example service discovery URLs:
https://dashboard.homelab     # Main dashboard
https://portainer.homelab     # Container management  
https://registry.homelab      # Container registry
https://gitea.homelab         # Git server
https://grafana.homelab       # Monitoring (future)
```

**Implementation Tasks:**
- [ ] Research CoreDNS custom zones and external-dns integration
- [ ] Design DNS zone structure and naming conventions
- [ ] Implement cert-manager for automatic SSL certificates
- [ ] Create Terraform/OpenTofu modules for DNS resources
- [ ] Integration with Traefik for automatic ingress creation
- [ ] Add DNS configuration to component selection system
- [ ] Create fallback mechanisms for DNS failures
- [ ] Documentation for custom domain configuration

**Integration Benefits:**
- **Gitea → Registry:** `https://registry.homelab/v2/` (no hardcoded IPs)
- **Dashboard → Services:** Dynamic service discovery and health checking
- **CI/CD Pipelines:** Consistent service endpoints
- **Mobile Access:** Remember friendly URLs instead of IP:port combinations
- **SSL Everywhere:** Automatic certificate generation and renewal

**Configuration Example:**
```yaml
# User selects components in dashboard:
components:
  portainer: enabled
  registry: enabled  
  gitea: enabled
  monitoring: disabled

# System automatically creates:
dns_records:
  - name: portainer.homelab
    target: portainer-service.default.svc.cluster.local
  - name: registry.homelab
    target: registry-ui-service.default.svc.cluster.local
  - name: gitea.homelab
    target: gitea-service.default.svc.cluster.local
```

**Acceptance Criteria:**
- All enabled services accessible via friendly DNS names
- Automatic SSL certificate generation and renewal
- Services can discover each other using DNS names
- Works across different network configurations
- Graceful degradation when DNS is unavailable
- Integration with component enable/disable functionality

**Estimated Effort:** Medium  
**Risk:** Medium (DNS configuration complexity)

---

### 5. Helm Chart Migration for Internal Applications
**Epic:** Migrate platform applications from Terraform to Helm charts

**Description:**
While Portainer provides excellent application deployment capabilities for end users, the internal platform applications (Portainer, Registry, future core services) would benefit from Helm chart management for better lifecycle management, templating, and version control.

**Current State:**
- Portainer: Deployed via raw Kubernetes resources in `terraform/portainer.tf`
- Registry: Deployed via raw Kubernetes resources in `terraform/registry.tf`
- Registry UI: Deployed via raw Kubernetes resources in `terraform/registry-ui.tf`
- Infrastructure components (Longhorn, MetalLB) already use Helm via Ansible

**Benefits of Helm Migration:**
- **Version Management:** Easy upgrades and rollbacks for platform services
- **Templating:** Reduce boilerplate with reusable chart templates
- **Values Management:** Cleaner configuration through values.yaml files
- **Ecosystem Integration:** Access to community Helm charts where available
- **Consistent Tooling:** Align with infrastructure components already using Helm
- **Release Management:** Better tracking of deployment history and status

**Proposed Architecture:**
```
homelab-platform/
├── charts/
│   ├── homelab-app/           # Generic template chart for platform apps
│   ├── portainer/             # Portainer-specific chart
│   └── registry/              # Registry + Registry UI chart
└── values/
    ├── portainer/
    │   └── values.yaml
    └── registry/
        └── values.yaml
```

**Implementation Tasks:**
- [ ] Create generic "homelab-app" Helm chart template with common patterns
  - PersistentVolumeClaim with Longhorn storage class
  - Service with MetalLB LoadBalancer annotations
  - Deployment with security contexts and resource limits
  - Kubelish mDNS service discovery annotations
- [ ] Convert Portainer Terraform to Helm chart
  - Migrate kubernetes resources to Helm templates
  - Create values.yaml with current configuration options
  - Test deployment and functionality parity
- [ ] Convert Registry and Registry UI to combined Helm chart
  - Create multi-service chart with registry + UI components
  - Maintain current configuration options
  - Ensure proper service dependencies
- [ ] Update Ansible playbook to deploy via Helm instead of Terraform
  - Replace `tofu apply` with `helm install/upgrade` commands
  - Add Helm repo management if using external charts
  - Maintain current variable passing from web config
- [ ] Create migration path for existing deployments
  - Export current Terraform state
  - Import resources into Helm releases
  - Verify no service interruption during migration
- [ ] Update web configuration interface
  - Modify backend to generate values.yaml instead of .tfvars
  - Update deployment process to use Helm commands
  - Maintain current user experience

**Integration with Ansible:**
```yaml
- name: Deploy Portainer via Helm
  kubernetes.core.helm:
    name: portainer
    chart_ref: /opt/homelab/charts/portainer
    release_namespace: default
    values_files:
      - /opt/homelab/values/portainer/values.yaml
    create_namespace: false

- name: Deploy Registry via Helm
  kubernetes.core.helm:
    name: registry
    chart_ref: /opt/homelab/charts/registry
    release_namespace: default
    values_files:
      - /opt/homelab/values/registry/values.yaml
```

**User Impact:**
- **No Change:** Users continue using Portainer for their own application deployments
- **Better Platform:** More reliable platform service updates and management
- **Future Ready:** Easier to add new platform services using established patterns

**Technical Benefits:**
- **Reduced Terraform Complexity:** Simpler Terraform state management
- **Better Abstractions:** Helm templates eliminate resource duplication
- **Community Charts:** Option to use existing charts where appropriate
- **Release Tracking:** Built-in deployment history and status monitoring

**Acceptance Criteria:**
- Portainer deployed via Helm with identical functionality to current Terraform
- Registry and Registry UI deployed via single Helm chart
- Web configuration interface continues to work without user-visible changes
- Migration from Terraform to Helm preserves all existing data and configurations
- Platform services can be easily updated via `helm upgrade`
- Documentation updated to reflect new deployment architecture

**Estimated Effort:** Medium (3-4 weeks)
**Risk:** Low (Helm is well-established, current infrastructure already uses it)

---

### 6. Modular Component Selection System
**Epic:** Allow users to choose which services to deploy

**Description:**
Transform the current "deploy everything" approach into a flexible system where users can select which components they want in their home lab.

**Component Categories:**

**Core Services (Always Enabled):**
- K3s Kubernetes cluster
- Traefik ingress controller
- Longhorn storage
- DNS resolution system
- Home Lab Dashboard

**Container Management:**
- [ ] Portainer (container management UI)
- [ ] Registry UI (container registry browser)
- [ ] Docker Registry (image storage)

**Development Tools:**
- [ ] Gitea (Git server + CI/CD)
- [ ] Code Server (VS Code in browser)
- [ ] Jenkins/Tekton (CI/CD pipelines)
- [ ] SonarQube (code quality)

**Monitoring & Observability:**
- [ ] Prometheus (metrics collection)
- [ ] Grafana (dashboards and visualization)
- [ ] AlertManager (alerting)
- [ ] Loki (log aggregation)
- [ ] Jaeger (distributed tracing)

**Productivity & Collaboration:**
- [ ] NextCloud (file sync and sharing)
- [ ] Bookstack/WikiJS (documentation)
- [ ] Mattermost/RocketChat (team chat)
- [ ] Calendar/Contact server

**Databases & Storage:**
- [ ] PostgreSQL (relational database)
- [ ] Redis (caching/session store)
- [ ] MinIO (S3-compatible object storage)
- [ ] InfluxDB (time-series database)

**Security & Network:**
- [ ] Pi-hole (DNS filtering/ad blocking)
- [ ] Nginx Proxy Manager (reverse proxy)
- [ ] Vault (secrets management)
- [ ] Wireguard (VPN server)

**Home Automation & IoT:**
- [ ] Home Assistant (smart home hub)
- [ ] MQTT Broker (IoT messaging)
- [ ] Node-RED (automation flows)
- [ ] Zigbee2MQTT (device integration)

**Implementation Approach:**

**Phase 1: Configuration System**
```yaml
# homelab-config.yaml
homelab:
  components:
    # Container Management
    portainer:
      enabled: true
      config:
        admin_password: "secure123"
        
    registry:
      enabled: true
      config:
        storage_size: "10Gi"
        
    # Development
    gitea:
      enabled: false
      config:
        admin_user: "admin"
        database: "postgres"  # postgres, mysql, sqlite
        
    # Monitoring  
    monitoring:
      enabled: false
      components:
        prometheus: true
        grafana: true
        alertmanager: false
```

**Phase 2: Dependency Management**
```yaml
# Component dependencies
dependencies:
  gitea:
    requires: ["postgres"]
    optional: ["registry", "monitoring"]
    
  monitoring:
    requires: ["prometheus"]
    includes: ["grafana", "alertmanager"]
    
  home-assistant:
    conflicts: ["pi-hole"]  # Port conflicts
    requires: ["mqtt-broker"]
```

**Phase 3: Dynamic Terraform Generation**
```hcl
# Generated based on user selection
module "portainer" {
  count  = var.components.portainer.enabled ? 1 : 0
  source = "./modules/portainer"
  config = var.components.portainer.config
}

module "gitea" {
  count  = var.components.gitea.enabled ? 1 : 0
  source = "./modules/gitea"
  config = var.components.gitea.config
  
  depends_on = [
    module.postgres,
    module.registry
  ]
}
```

**Phase 4: Web Interface Integration**
- Component selection in dashboard UI
- Real-time dependency validation
- Resource requirement calculation
- Preview of what will be deployed
- One-click enable/disable with safety checks

**Implementation Tasks:**
- [ ] Define component taxonomy and relationships
- [ ] Create modular Terraform/OpenTofu modules
- [ ] Implement dependency resolver
- [ ] Build component selection UI
- [ ] Create configuration validation system
- [ ] Implement safe enable/disable operations
- [ ] Add resource requirement calculator
- [ ] Create component health monitoring
- [ ] Build backup/restore for component data
- [ ] Documentation for each component

**User Experience Flow:**
1. **Initial Setup:** Select core components during installation
2. **Dashboard Management:** Enable/disable components via web UI
3. **Dependency Handling:** Automatic resolution and conflict detection
4. **Resource Planning:** Show impact on system resources
5. **Safe Operations:** Backup data before disabling components

**Technical Challenges:**
- **State Management:** Terraform state with dynamic modules
- **Dependency Resolution:** Complex inter-service dependencies
- **Resource Conflicts:** Port, storage, and memory conflicts
- **Data Migration:** Moving data when reconfiguring components
- **Service Integration:** Automatic service discovery and configuration

**Acceptance Criteria:**
- Users can select components during initial setup
- Components can be safely enabled/disabled post-installation
- Dependency conflicts are automatically detected and resolved
- System remains stable when reconfiguring components
- All component data is preserved during enable/disable cycles
- Integration between enabled components works automatically

**Estimated Effort:** Large  
**Risk:** High (complex state management and dependencies)

---

### 6. Multi-Node Cluster Support
**Description:** Extend support for multi-Raspberry Pi clusters
- Automated node joining and discovery
- Load balancing and high availability
- Distributed storage configuration
- Network segmentation and security

**Estimated Effort:** Large  
**Risk:** High

---

### 8. Configurable Network Subnets for Scalability
**Epic:** Allow configuration of K3s pod and service network sizes

**Description:**
The current default K3s configuration uses `/24` subnets (255 addresses) for both pod and service networks. For larger home labs or future expansion, this may be insufficient. Add the ability to configure larger subnets.

**Current Limitations:**
- **Pod CIDR:** `10.42.0.0/24` (254 usable IPs)
- **Service CIDR:** `10.43.0.0/24` (254 usable IPs)
- **Max Pods per Node:** Limited by available pod IPs
- **Max Services:** Limited to 254 LoadBalancer services

**Proposed Enhancement:**
Support configurable subnet sizes with sensible defaults:

**Option A: Configurable Subnet Sizes**
```yaml
# homelab-config.yaml
network:
  pod_cidr: "10.42.0.0/16"      # 65,534 IPs (recommended)
  service_cidr: "10.43.0.0/16"  # 65,534 IPs
  
  # Alternative smaller configs for resource-constrained setups
  # pod_cidr: "10.42.0.0/20"    # 4,094 IPs
  # service_cidr: "10.43.0.0/20" # 4,094 IPs
```

**Option B: Preset Configurations**
```yaml
network:
  size: large  # small (/24), medium (/20), large (/16)
  
# Translates to:
# small:  pod=/24 (254), service=/24 (254)
# medium: pod=/20 (4094), service=/20 (4094)  
# large:  pod=/16 (65534), service=/16 (65534)
```

**Implementation Requirements:**

**K3s Configuration:**
```bash
# Install K3s with custom CIDRs
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="\
  --cluster-cidr=10.42.0.0/16 \
  --service-cidr=10.43.0.0/16" sh -
```

**MetalLB Pool Configuration:**
```yaml
# Adjust MetalLB address pools based on service CIDR
apiVersion: v1
kind: ConfigMap
metadata:
  name: config
  namespace: metallb-system
data:
  config: |
    address-pools:
    - name: homelab-services
      protocol: layer2
      addresses:
      - 10.43.100.0-10.43.200.255  # Subset of service CIDR
```

**Router/Client Route Configuration:**
```bash
# Update routing to match configured subnet sizes
sudo ip route add ${SERVICE_CIDR} via ${PI_IP}

# Example with /16:
sudo ip route add 10.43.0.0/16 via 192.168.1.28
```

**Benefits of Larger Subnets (/16):**

**Scalability:**
- **65,534 pod IPs** vs 254 (262x increase)
- **Support for multiple nodes** without subnet conflicts
- **Room for growth** as home lab expands
- **No IP planning stress** for new services

**Multi-Node Ready:**
```
Node 1: 10.42.0.0/24   (pods)
Node 2: 10.42.1.0/24   (pods)
Node 3: 10.42.2.0/24   (pods)
...
Node 256: 10.42.255.0/24 (pods)
```

**Service Separation:**
```
10.43.0.0/20     # Core services (dashboard, monitoring)
10.43.16.0/20    # Development services (gitea, registry)
10.43.32.0/20    # Databases and storage
10.43.48.0/20    # IoT and automation
```

**Considerations:**

**Router Compatibility:**
- Most home routers handle /16 routes fine
- Larger routing tables (minimal impact)
- No functional differences for end users

**Memory Usage:**
- K3s uses slightly more memory for larger IP tables
- Negligible impact on Raspberry Pi 4 (4GB+)
- MetalLB ARP table scales linearly

**IP Address Space:**
- Uses more RFC1918 private space
- No conflicts with typical home networks
- Leaves room for other private subnets

**Migration Strategy:**

**New Installations:**
- Default to /16 subnets for future-proofing
- Provide /24 option for resource-constrained setups

**Existing Installations:**
- Provide migration guide for subnet expansion
- Backup/restore process for data preservation
- Blue/green deployment for zero-downtime migration

**Implementation Tasks:**
- [ ] Research K3s CIDR configuration options and limitations
- [ ] Design configuration schema for network sizing
- [ ] Update installation scripts to support custom CIDRs
- [ ] Modify MetalLB configuration generation
- [ ] Update routing setup scripts for variable subnet sizes
- [ ] Create migration tools for existing deployments
- [ ] Add validation for subnet conflicts and overlaps
- [ ] Update documentation with network planning guide
- [ ] Test multi-node scenarios with larger subnets
- [ ] Create troubleshooting guide for network issues

**Configuration Validation:**
```bash
# Validate subnet configurations don't conflict
validate_network_config() {
    local pod_cidr="$1"
    local service_cidr="$2"
    local host_network="192.168.1.0/24"
    
    # Check for overlaps with host network
    # Check for overlaps between pod and service CIDRs
    # Validate subnet sizes are appropriate for hardware
}
```

**User Interface:**
- Network configuration section in web dashboard
- Real-time validation of subnet configurations
- Visual network topology display
- IP usage monitoring and alerts

**Acceptance Criteria:**
- Users can configure pod and service subnet sizes during installation
- Default configuration uses /16 subnets for future-proofing
- Existing /24 installations can migrate to larger subnets
- All routing and service discovery works with configurable subnets
- Multi-node deployments automatically use appropriate subnet allocation
- Network configuration is validated to prevent conflicts

**Estimated Effort:** Medium  
**Risk:** Medium (network configuration complexity)

---

### 9. Backup and Disaster Recovery
**Description:** Automated backup and recovery systems
- Scheduled backups of persistent data
- Configuration backup and versioning
- One-click recovery procedures
- External backup storage integration (S3, NFS)

**Estimated Effort:** Medium  
**Risk:** Low

### 6. Monitoring and Alerting Stack
**Description:** Comprehensive monitoring solution
- Prometheus metrics collection
- Grafana dashboards
- AlertManager for notifications
- Log aggregation with Loki or ELK
- Health check automation

**Estimated Effort:** Large  
**Risk:** Medium

### 7. GitOps Integration
**Description:** Git-based operations workflow
- ArgoCD or Flux deployment
- Git-based configuration management
- Automated application deployment pipelines
- Infrastructure drift detection

**Estimated Effort:** Medium  
**Risk:** Medium

### 8. Enhanced Security Features
**Description:** Additional security hardening
- Network policies and segmentation
- Pod security policies/standards
- Secrets management with Vault
- Certificate rotation automation
- Security scanning and compliance

**Estimated Effort:** Large  
**Risk:** Medium

### 9. Development Tools Integration
**Description:** Developer-focused enhancements
- Code server (VS Code in browser)
- Git server (Gitea/GitLab)
- CI/CD pipelines (Jenkins/Tekton)
- Development databases and caches
- Testing environments

**Estimated Effort:** Large  
**Risk:** Low

### 10. IoT and Home Automation Integration
**Description:** Smart home integration capabilities
- Home Assistant deployment
- MQTT broker setup
- Device discovery and management
- Automation rule engine
- Mobile app integration

**Estimated Effort:** Medium  
**Risk:** Medium

---

## 🔄 Technical Debt

### Code Quality Improvements
- [ ] Add comprehensive error handling to all scripts
- [ ] Implement logging framework for better debugging
- [ ] Add unit tests for critical functions
- [ ] Code linting and formatting standards
- [ ] Documentation improvements and API docs

### Performance Optimizations
- [ ] Optimize container image sizes
- [ ] Implement resource limits and requests
- [ ] Storage performance tuning
- [ ] Network optimization for Pi hardware
- [ ] Boot time optimization

### Maintainability Enhancements
- [ ] Modularize large scripts into smaller functions
- [ ] Standardize configuration file formats
- [ ] Implement configuration validation
- [ ] Create automated testing pipeline
- [ ] Dependency version management

---

## 📊 Backlog Prioritization Criteria

**High Priority:** Essential features that improve core functionality or address significant technical debt

**Medium Priority:** Features that enhance usability and maintainability but don't block current functionality

**Low Priority:** Nice-to-have features that add value but require significant development effort

**Risk Assessment:**
- **Low:** Well-understood technology with minimal integration complexity
- **Medium:** Some unknown factors or moderate integration challenges
- **High:** Significant unknowns or complex system interactions

**Effort Estimation:**
- **Small:** 1-2 weeks of development
- **Medium:** 3-6 weeks of development  
- **Large:** 6+ weeks of development

---

## 🚦 Implementation Guidelines

1. **Research Phase:** Evaluate options and create detailed technical design
2. **Prototype:** Build minimal viable implementation
3. **Testing:** Comprehensive testing on clean systems
4. **Documentation:** Update all relevant documentation
5. **Integration:** Merge with main codebase
6. **Validation:** Ensure backward compatibility and migration paths

## 📝 Contributing

To add items to this backlog:
1. Create detailed feature description
2. Identify implementation tasks and acceptance criteria
3. Estimate effort and risk level
4. Consider integration with existing system
5. Update this document via pull request
