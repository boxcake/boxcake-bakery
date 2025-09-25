# Deployment Order

This document outlines the correct order for deploying the homelab infrastructure.

## Chicken-and-Egg Problem

The custom images need to be pushed to the local registry, but the registry is deployed by Terraform.

## Deployment Steps

### 1. Run Ansible (Infrastructure Setup)

```bash
cd ansible/
# Deploy K3s, Docker, base infrastructure
ansible-playbook -i inventory playbook.yml
```

### 2. Deploy Core Services (Registry First)

```bash
cd terraform/
terraform init

# Deploy only the registry service first
terraform apply -target=kubernetes_service.registry_service -target=kubernetes_deployment.registry
```

### 3. Build and Push Custom Images

```bash
cd ansible/
# Now that registry is running, build and push images
ansible-playbook -i inventory playbook.yml --tags images
```

### 4. Deploy Everything Else

```bash
cd terraform/
# Deploy remaining services (including those needing custom images)
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