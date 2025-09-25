# Image Builder Role

This role builds and pushes custom Docker images to the local container registry.

## Images Built

### portainer-config
- **Purpose:** Configuration container for Portainer setup
- **Base:** Alpine Linux 3.19
- **Tools:** curl, jq, bind-tools, ca-certificates
- **Registry Location:** `registry-service:5000/portainer-config:latest`

## Prerequisites

- Docker installed on the Ansible control node
- K3s cluster running with container registry service
- `kubernetes.core` collection installed: `ansible-galaxy collection install kubernetes.core`

## Usage

```yaml
# In your playbook
- name: Build custom images
  include_role:
    name: image-builder
  tags: images
```

## Variables

- `k8s_namespace`: Kubernetes namespace (default: 'default')

## Dependencies

This role must be run **before** applying Terraform configurations that reference these images.

## Tags

- `images`: Build all custom images
- `portainer-config`: Build only the portainer-config image