# Docker Container Registry

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

          env {
            name  = "REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY"
            value = "/var/lib/registry"
          }

          env {
            name  = "REGISTRY_HTTP_ADDR"
            value = "0.0.0.0:5000"
          }

          env {
            name  = "REGISTRY_STORAGE_DELETE_ENABLED"
            value = tostring(var.allow_registry_deletion)
          }

          env {
            name  = "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Origin"
            value = "[*]"
          }

          env {
            name  = "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods"
            value = "[HEAD,GET,OPTIONS,DELETE]"
          }

          env {
            name  = "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers"
            value = "[Authorization,Accept,Cache-Control]"
          }

          env {
            name  = "REGISTRY_HTTP_HEADERS_Access-Control-Max-Age"
            value = "[1728000]"
          }

          env {
            name  = "REGISTRY_HTTP_HEADERS_Access-Control-Allow-Credentials"
            value = "[true]"
          }

          env {
            name  = "REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers"
            value = "[Docker-Content-Digest]"
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