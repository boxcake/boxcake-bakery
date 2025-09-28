# Home Lab Kubernetes Resources

This directory contains OpenTofu/Terraform configuration for deploying Kubernetes resources in your home lab.

## 🎯 What's Managed Here

- **Portainer**: Container management UI with automatic configuration
- **Registry UI**: Web interface for browsing your local Docker registry

## 🚀 Quick Start

1. **Initialize OpenTofu**:
   ```bash
   cd terraform/
   tofu init
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Plan Deployment**:
   ```bash
   tofu plan -state=/home/homelab/tfstate/terraform.tfstate
   ```

4. **Deploy Resources**:
   ```bash
   tofu apply -state=/home/homelab/tfstate/terraform.tfstate
   ```

5. **View Outputs**:
   ```bash
   tofu output -state=/home/homelab/tfstate/terraform.tfstate
   ```

## 🧹 Cleanup

To remove all resources:

```bash
tofu destroy -state=/home/homelab/tfstate/terraform.tfstate
```

## 📁 File Structure

```
terraform/
├── providers.tf           # Provider configuration
├── variables.tf           # Input variables
├── portainer.tf          # Portainer resources
├── registry-ui.tf        # Registry UI resources
├── outputs.tf            # Output values
├── scripts/
│   └── configure-portainer.sh  # Portainer configuration script
├── terraform.tfvars.example    # Example variables
└── README.md             # This file
```

## ⚙️ Configuration

Key variables to customize in `terraform.tfvars`:

| Variable | Description | Default |
|----------|-------------|---------|
| `host_ip` | Your Pi's IP address | Required |
| `portainer_admin_password` | Portainer admin password | `homelab123!` |
| `registry_port` | Docker registry port | `5000` |
| `metallb_pool_name` | MetalLB address pool | `homelab-services` |

## 🌐 Access URLs

After deployment, access your services:

- **Portainer**: Check `tofu output -state=/home/homelab/tfstate/terraform.tfstate portainer_urls`
- **Registry UI**: Check `tofu output -state=/home/homelab/tfstate/terraform.tfstate registry_ui_urls`

## 🔐 Security Notes

- Change the default Portainer admin password
- The `terraform.tfvars` file contains sensitive data - don't commit it to git
- Portainer runs with cluster-admin privileges for full Kubernetes management

## 🔄 State Management

OpenTofu maintains state in `terraform.tfstate`. This file:
- Tracks all deployed resources
- Enables proper updates and cleanup
- Should be backed up for production use

## 🛠️ Troubleshooting

**Resource won't delete?**
```bash
tofu state list -state=/home/homelab/tfstate/terraform.tfstate
tofu state rm -state=/home/homelab/tfstate/terraform.tfstate <resource_name>  # Remove from state only
kubectl delete <resource>      # Delete from cluster
```

**State issues?**
```bash
tofu refresh -state=/home/homelab/tfstate/terraform.tfstate  # Sync state with cluster
```

**Check deployment status:**
```bash
kubectl get pods,svc -l app=portainer
kubectl get pods,svc -l app=registry-ui
```