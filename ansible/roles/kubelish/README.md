# Kubelish Ansible Role

This Ansible role deploys kubelish, a tool that announces Kubernetes LoadBalancer services via mDNS, making them discoverable on the local network.

## Requirements

- Ansible 2.9+
- `kubernetes.core` collection
- `avahi-daemon` and `libnss-mdns` packages (should be installed by your system prep role)
- Access to a Kubernetes cluster with kubectl configured

## Role Variables

### Default Variables (can be overridden)

```yaml
# Kubelish binary configuration
kubelish_version: "latest"
kubelish_download_url: "https://github.com/kvaps/kubelish/releases/latest/download/kubelish-linux-amd64"

# Kubernetes configuration
kubernetes_api_url: "https://{{ ansible_default_ipv4.address }}:6443"
kubeconfig_path: "~/.kube/config"

# Service configuration
kubelish_restart_sec: 5
kubelish_limit_nofile: 65536

# Avahi configuration
avahi_enable_reflector: yes
```

## Dependencies

- The `kubernetes.core` collection must be installed
- `avahi-daemon` and `libnss-mdns` should be pre-installed

## Example Playbook

```yaml
- hosts: kubernetes_masters
  become: yes
  roles:
    - role: kubelish
      vars:
        kubernetes_api_url: "https://10.0.1.100:6443"
        kubeconfig_path: "/root/.kube/config"
```

## What This Role Does

1. **Configures Avahi**: Enables reflector mode in `/etc/avahi/avahi-daemon.conf` to forward mDNS requests across network interfaces
2. **Downloads kubelish**: Downloads the kubelish binary to `/usr/local/bin/kubelish`
3. **Sets up Kubernetes RBAC**: Creates a service account, cluster role, and cluster role binding for kubelish
4. **Extracts Service Account Token**: Retrieves the token for the kubelish service account
5. **Creates Systemd Service**: Sets up a systemd service for kubelish with proper security settings
6. **Starts Services**: Enables and starts both avahi-daemon and kubelish services

## Security Features

The systemd service includes several security hardening measures:
- Runs as `nobody:nogroup`
- No new privileges
- Protected system and home directories
- Private temporary directory
- Kernel protection settings

## Manual Service Management

After deployment, you can manage the kubelish service with:

```bash
# Check status
sudo systemctl status kubelish

# View logs
sudo journalctl -u kubelish -f

# Restart service
sudo systemctl restart kubelish
```

## Troubleshooting

1. **Service fails to start**: Check that the Kubernetes API is accessible and the token is valid
2. **mDNS not working**: Ensure avahi-daemon is running and reflector mode is enabled
3. **Permission issues**: Verify the RBAC configuration was applied correctly

## License

MIT

## Author Information

Created for deploying kubelish in Kubernetes environments with mDNS support.