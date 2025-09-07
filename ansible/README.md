# Ansible-based Home Lab Pi Setup

This directory contains a complete Ansible-based setup for Home Lab Pi that replaces the bash script approach with a more robust, idempotent configuration management system.

## 🏗️ Structure

```
ansible/
├── site.yml                    # Main playbook
├── vars/
│   ├── main.yml               # Main variables
│   └── network.yml            # Network configuration
├── inventory/
│   └── hosts.yml              # Dynamic inventory (created by setup script)
├── templates/                 # Global templates
└── roles/
    ├── system-prep/           # System packages and preparation
    ├── homelab-user/          # User creation and configuration
    ├── docker/                # Docker installation
    ├── k3s/                   # K3s Kubernetes setup
    ├── storage/               # Helm + Longhorn storage
    ├── load-balancer/         # MetalLB load balancer (TODO)
    ├── container-registry/    # Docker registry service (TODO)
    └── applications/          # Portainer + Terraform (TODO)
```

## 🚀 Usage

Run the Ansible-based setup:

```bash
sudo ./setup-via-ansible.sh
```

This will:
1. Install Ansible if not present
2. Create dynamic inventory
3. Run the complete playbook
4. Provide access URLs and next steps

## ✅ Completed Roles

- **system-prep**: System updates, essential packages, yq, iSCSI
- **homelab-user**: User creation, .bashrc, sudo configuration  
- **docker**: Docker installation and configuration
- **k3s**: K3s with custom network CIDRs, registry config
- **storage**: Helm installation + Longhorn deployment

## 🔄 TODO Roles

- **load-balancer**: MetalLB installation and IP pool configuration
- **container-registry**: Docker registry systemd service
- **applications**: Portainer + Terraform deployment

## 🎯 Benefits Over Bash Scripts

- **Idempotent**: Safe to run multiple times
- **Atomic**: Individual tasks succeed or fail cleanly
- **Templating**: Dynamic configuration from variables
- **Error Handling**: Built-in retry and validation
- **Modular**: Each role is independent and reusable
- **Inventory**: Easy to extend to multi-node setups
- **Facts**: Automatic system discovery and adaptation

## 🔧 Customization

Edit variables in:
- `vars/main.yml` - Tool versions, ports, paths
- `vars/network.yml` - Network configuration (uses existing network-defaults.yaml)
- Role-specific variables in each role's defaults/

## 🧪 Development

Test individual roles:

```bash
# Test just the user creation
ansible-playbook -i inventory/hosts.yml site.yml --tags user

# Test storage setup only  
ansible-playbook -i inventory/hosts.yml site.yml --tags storage

# Skip system prep (useful for testing)
ansible-playbook -i inventory/hosts.yml site.yml --skip-tags system
```

## 📝 Next Steps

1. Complete remaining roles (load-balancer, container-registry, applications)
2. Add comprehensive error handling and validation
3. Create ansible-vault encryption for sensitive variables
4. Add support for multiple inventory configurations
5. Create uninstall playbook to complement uninstall.sh
