# Troubleshooting Guide

This guide helps resolve common issues with Home Lab Pi.

## Installation Issues

### Script Permission Denied

**Problem:** `./setup.sh: Permission denied`

**Solution:**
```bash
chmod +x setup.sh
sudo ./setup.sh
```

### Docker Installation Fails

**Problem:** Docker installation fails or times out

**Solutions:**
1. **Check internet connection:**
   ```bash
   ping google.com
   ```

2. **Manual Docker installation:**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

3. **Check Docker status:**
   ```bash
   sudo systemctl status docker
   ```

### K3s Installation Issues

**Problem:** K3s fails to start or install

**Solutions:**
1. **Check system resources:**
   ```bash
   free -h  # Should have at least 1GB available RAM
   df -h    # Should have at least 2GB free disk space
   ```

2. **Manual K3s installation:**
   ```bash
   curl -sfL https://get.k3s.io | sh -
   sudo systemctl status k3s
   ```

3. **Check K3s logs:**
   ```bash
   sudo journalctl -u k3s -f
   ```

## Runtime Issues

### Cannot Access Web Interfaces

**Problem:** Portainer/Registry UI not accessible

**Diagnostics:**
```bash
# Check if pods are running
kubectl get pods

# Check services
kubectl get svc

# Check node status
kubectl get nodes
```

**Solutions:**
1. **Wait for pods to start:**
   ```bash
   kubectl get pods -w  # Watch pod status
   ```

2. **Check pod logs:**
   ```bash
   kubectl logs -l app=portainer
   kubectl logs -l app=registry-ui
   ```

3. **Restart services:**
   ```bash
   kubectl rollout restart deployment/portainer
   kubectl rollout restart deployment/registry-ui
   ```

### Registry Not Working

**Problem:** Cannot push/pull images to local registry

**Diagnostics:**
```bash
# Check registry service
sudo systemctl status docker-registry

# Test registry API
curl http://localhost:5000/v2/_catalog

# Check registry logs
sudo journalctl -u docker-registry -f
```

**Solutions:**
1. **Restart registry service:**
   ```bash
   sudo systemctl restart docker-registry
   ```

2. **Check registry configuration:**
   ```bash
   cat /etc/rancher/k3s/registries.yaml
   ```

3. **Restart K3s to reload config:**
   ```bash
   sudo systemctl restart k3s
   ```

### Terraform Issues

**Problem:** Terraform fails to deploy services

**Diagnostics:**
```bash
# Switch to homelab user
sudo -u homelab -i

# Check Terraform status
cd ~/homelab-pi/terraform
terraform plan
```

**Solutions:**
1. **Check kubeconfig:**
   ```bash
   export KUBECONFIG=~/.kube/config
   kubectl get nodes
   ```

2. **Reinitialize Terraform:**
   ```bash
   rm -rf .terraform
   terraform init
   terraform plan
   ```

3. **Check Terraform logs:**
   ```bash
   terraform apply -auto-approve 2>&1 | tee terraform.log
   ```

## Network Issues

### Cannot Access from Other Devices

**Problem:** Services only accessible from Pi itself

**Solutions:**
1. **Check firewall:**
   ```bash
   sudo ufw status
   # If active, add rules:
   sudo ufw allow 32090  # Portainer
   sudo ufw allow 32080  # Registry UI
   sudo ufw allow 5000   # Registry
   ```

2. **Check IP binding:**
   ```bash
   sudo netstat -tlnp | grep -E "(32090|32080|5000)"
   ```

3. **Use correct IP address:**
   ```bash
   hostname -I  # Get Pi's IP address
   ```

### DNS Resolution Issues

**Problem:** Ingress hostnames don't resolve

**Solutions:**
1. **Add to /etc/hosts:**
   ```bash
   echo "PI-IP-ADDRESS registry.local portainer.local" | sudo tee -a /etc/hosts
   ```

2. **Use NodePort instead:**
   - Portainer: http://PI-IP:32090
   - Registry UI: http://PI-IP:32080

## Resource Issues

### Out of Memory

**Problem:** Services crashing due to low memory

**Diagnostics:**
```bash
free -h
top
kubectl top nodes  # If metrics-server is installed
```

**Solutions:**
1. **Increase swap:**
   ```bash
   sudo dphys-swapfile swapoff
   sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```

2. **Reduce resource usage:**
   ```bash
   # Scale down replicas
   kubectl scale deployment/portainer --replicas=1
   kubectl scale deployment/registry-ui --replicas=1
   ```

### Out of Disk Space

**Problem:** No space left on device

**Diagnostics:**
```bash
df -h
du -sh /var/lib/docker
du -sh /opt/registry/data
```

**Solutions:**
1. **Clean Docker:**
   ```bash
   docker system prune -a
   ```

2. **Clean old images:**
   ```bash
   kubectl get pods --all-namespaces | grep -E "(Error|Evicted|Completed)"
   # Delete problematic pods
   ```

3. **Expand storage:**
   ```bash
   sudo raspi-config  # Advanced Options -> Expand Filesystem
   ```

## Service User Issues

### Cannot Switch to Homelab User

**Problem:** `sudo -u homelab -i` fails

**Solutions:**
1. **Check user exists:**
   ```bash
   id homelab
   ```

2. **Recreate user if needed:**
   ```bash
   sudo ./scripts/create-user.sh $USER
   ```

3. **Check sudoers file:**
   ```bash
   sudo cat /etc/sudoers.d/homelab
   ```

## Getting Help

### Collect System Information

```bash
# System info
uname -a
cat /etc/os-release

# Service status
sudo systemctl status k3s docker docker-registry

# Resource usage
free -h
df -h

# Network info
ip addr show
```

### Log Collection

```bash
# Collect all relevant logs
sudo journalctl -u k3s > k3s.log
sudo journalctl -u docker > docker.log
sudo journalctl -u docker-registry > registry.log
kubectl get events --all-namespaces > k8s-events.log
kubectl get pods -o wide --all-namespaces > pods.log
```

### Reset Everything

If all else fails, you can reset the entire installation:

```bash
# Stop services
sudo systemctl stop docker-registry k3s docker

# Remove K3s
sudo /usr/local/bin/k3s-uninstall.sh

# Remove Docker (optional)
sudo apt-get remove docker-ce docker-ce-cli containerd.io

# Remove homelab user
sudo userdel -r homelab

# Remove configuration
sudo rm -rf /etc/rancher /opt/registry

# Start fresh
git pull  # Get latest version
sudo ./setup.sh
```

## Common Error Messages

### "connection refused"
- Service not running or wrong port
- Check service status and port binding

### "permission denied" 
- User lacks required permissions
- Check sudoers configuration and user groups

### "no space left on device"
- Disk full - clean up or expand storage

### "image pull backoff"
- Network issues or registry unavailable
- Check registry service and network connectivity

### "pending" pods
- Resource constraints or scheduling issues
- Check node resources and pod requirements
