# Deployment Order

This document outlines the correct order for deploying the homelab infrastructure.

## Prerequisites

1. **Ansible Setup** - Must be completed before Terraform
2. **Custom Images** - Built and pushed to local registry

## Deployment Steps

### 1. Run Ansible Playbooks

```bash
cd ansible/

# Build custom Docker images (including portainer-config)
ansible-playbook -i inventory playbook.yml --tags images

# Complete Ansible setup
ansible-playbook -i inventory playbook.yml
```

### 2. Apply Terraform Configuration

```bash
cd terraform/

# Initialize and apply
terraform init
terraform apply
```

## Image Dependencies

The following Terraform resources depend on custom images built by Ansible:

- **`kubernetes_job.portainer_configure`** → Requires `registry-service:5000/portainer-config:latest`
  - Built by: `ansible/roles/image-builder`
  - Contains: curl, jq, bind-tools for Portainer API configuration

## Troubleshooting

If you see image pull errors:
1. Verify the image exists: `curl -s http://<registry-ip>:5000/v2/_catalog`
2. Re-run the image-builder role: `ansible-playbook playbook.yml --tags images`
3. Check registry service is running: `kubectl get service registry-service`