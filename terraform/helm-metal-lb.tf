# MetalLB configuration from YAML config
locals {
  # Read network configuration from YAML
  network_config = yamldecode(file("${path.module}/../configs/network-defaults.yaml"))
  homelab_pool   = local.network_config.homelab.network.pools.homelab.cidr
  user_pool      = local.network_config.homelab.network.pools.user.cidr
}

# Deploy MetalLB via Helm
resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = "metallb-system"
  create_namespace = true

  values = [
    yamlencode({
      configInline = {
        address-pools = [
          {
            name      = "homelab-services"
            protocol  = "layer2"
            addresses = [local.homelab_pool]
          },
          {
            name      = "user-services"
            protocol  = "layer2"
            addresses = [local.user_pool]
          }
        ]
      }
    })
  ]
}

# MetalLB namespace (if not already created)
resource "kubernetes_namespace" "metallb_system" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}
