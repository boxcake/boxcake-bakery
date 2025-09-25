# Docker Container Registry

# ConfigMap for Registry configuration
resource "kubernetes_config_map" "registry_config" {
  metadata {
    name      = "registry-config"
    namespace = var.namespace

    labels = {
      app = "registry"
    }
  }

  data = {
    "config.yml" = <<-EOT
      version: 0.1
      log:
        fields:
          service: registry
      storage:
        cache:
          blobdescriptor: inmemory
        filesystem:
          rootdirectory: /var/lib/registry
        delete:
          enabled: ${var.allow_registry_deletion}
      http:
        addr: :5000
        headers:
          X-Content-Type-Options: [nosniff]
          Access-Control-Allow-Origin: ['*']
          Access-Control-Allow-Methods: [HEAD,GET,OPTIONS,DELETE]
          Access-Control-Allow-Headers: [Authorization,Accept,Cache-Control]
          Access-Control-Max-Age: [1728000]
          Access-Control-Allow-Credentials: [true]
          Access-Control-Expose-Headers: [Docker-Content-Digest]
      health:
        storagedriver:
          enabled: true
          interval: 10s
          threshold: 3
    EOT
  }
}

# Persistent Volume Claim for Registry data
resource "kubernetes_persistent_volume_claim" "registry_pvc" {
  metadata {
    name      = "registry-pvc"
    namespace = var.namespace

    labels = {
      app = "registry"
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"

    resources {
      requests = {
        storage = var.registry_storage_size
      }
    }
  }
}

# Registry Deployment
resource "kubernetes_deployment" "registry" {
  metadata {
    name      = "registry"
    namespace = var.namespace

    labels = {
      app = "registry"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "registry"
      }
    }

    template {
      metadata {
        labels = {
          app = "registry"
        }
      }

      spec {
        # Ensure registry runs on the Kubernetes master/control plane node
        node_selector = {
          "node-role.kubernetes.io/control-plane" = "true"
        }

        # Tolerate master node taints
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          name  = "registry"
          image = var.registry_image

          port {
            container_port = 5000
            name           = "registry"
          }

          volume_mount {
            name       = "registry-data"
            mount_path = "/var/lib/registry"
          }

          volume_mount {
            name       = "registry-config"
            mount_path = "/etc/docker/registry"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }

          liveness_probe {
            http_get {
              path = "/v2/"
              port = 5000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/v2/"
              port = 5000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }

        volume {
          name = "registry-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.registry_pvc.metadata[0].name
          }
        }

        volume {
          name = "registry-config"
          config_map {
            name = kubernetes_config_map.registry_config.metadata[0].name
          }
        }
      }
    }
  }
}

# Registry Service (ClusterIP for internal access)
resource "kubernetes_service" "registry_service" {
  metadata {
    name      = "registry-service"
    namespace = var.namespace

    labels = {
      app = "registry"
    }
  }

  spec {
    type = "ClusterIP"

    port {
      name        = "registry"
      port        = 5000
      target_port = 5000
      protocol    = "TCP"
    }

    selector = {
      app = "registry"
    }
  }

  depends_on = [kubernetes_deployment.registry]
}

# Registry LoadBalancer Service for external access
resource "kubernetes_service" "registry_loadbalancer" {
  metadata {
    name      = "registry-loadbalancer"
    namespace = var.namespace

    annotations = {
      "metallb.universe.tf/address-pool" = var.metallb_pool_name
    }

    labels = {
      app = "registry"
    }
  }

  spec {
    type = "LoadBalancer"

    port {
      name        = "registry"
      port        = var.registry_port
      target_port = 5000
      protocol    = "TCP"
    }

    selector = {
      app = "registry"
    }
  }

  depends_on = [kubernetes_deployment.registry]
}