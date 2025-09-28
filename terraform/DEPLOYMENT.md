# Deployment Order

This document outlines the correct order for deploying the homelab infrastructure.

## Deployment Steps

### 1. Run Ansible (Infrastructure Setup)

```bash
cd ansible/
# Deploy K3s, Docker, base infrastructure, and Kubernetes services
ansible-playbook -i inventory site.yml
```

### 2. Deploy Services with Terraform/OpenTofu

```bash
cd terraform/
# Deploy container registry, portainer, etc.
terraform init
terraform apply
```

### 3. Optional: Configure Portainer via Ansible

```bash
cd ansible/
# Alternative method to configure Portainer directly from Ansible
ansible-playbook -i inventory site.yml --tags portainer-config -e "portainer_configure_via_ansible=true"
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