# Portainer Container Management UI

# Persistent Volume Claim for Portainer data
resource "kubernetes_persistent_volume_claim" "portainer_pvc" {
  metadata {
    name      = "portainer-pvc"
    namespace = var.namespace

    labels = {
      app = "portainer"
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"

    resources {
      requests = {
        storage = var.portainer_storage_size
      }
    }
  }
}

# Service Account for Portainer
resource "kubernetes_service_account" "portainer_sa" {
  metadata {
    name      = "portainer-sa"
    namespace = var.namespace
  }
}

# Cluster Role Binding for Portainer (admin access)
resource "kubernetes_cluster_role_binding" "portainer_crb" {
  metadata {
    name = "portainer-crb"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.portainer_sa.metadata[0].name
    namespace = var.namespace
  }
}

# Portainer Deployment
resource "kubernetes_deployment" "portainer" {
  metadata {
    name      = "portainer"
    namespace = var.namespace

    labels = {
      app = "portainer"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "portainer"
      }
    }

    template {
      metadata {
        labels = {
          app = "portainer"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.portainer_sa.metadata[0].name

        container {
          name  = "portainer"
          image = var.portainer_image

          port {
            container_port = 9000
            name           = "http"
          }

          port {
            container_port = 9443
            name           = "https"
          }

          volume_mount {
            name       = "portainer-data"
            mount_path = "/data"
          }

          env {
            name  = "PORTAINER_TEMPLATES"
            value = "https://raw.githubusercontent.com/portainer/templates/master/templates.json"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          security_context {
            run_as_user = 0
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 9000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 9000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }

        volume {
          name = "portainer-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.portainer_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# Portainer LoadBalancer Service
resource "kubernetes_service" "portainer_service" {
  metadata {
    name      = "portainer-service"
    namespace = var.namespace

    annotations = {
      "metallb.universe.tf/address-pool" = var.metallb_pool_name
    }
  }

  spec {
    type = "LoadBalancer"

    port {
      name        = "http"
      port        = 80
      target_port = 9000
    }

    port {
      name        = "https"
      port        = 443
      target_port = 9443
    }

    selector = {
      app = "portainer"
    }
  }

  depends_on = [kubernetes_deployment.portainer]
}

# Configuration Job for Portainer
resource "kubernetes_job" "portainer_configure" {
  metadata {
    name      = "portainer-configure"
    namespace = var.namespace

    labels = {
      app = "portainer-configure"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app = "portainer-configure"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "configure"
          image = "curlimages/curl:8.4.0"

          command = ["/bin/sh"]
          args = [
            "-c",
            templatefile("${path.module}/scripts/configure-portainer.sh", {
              namespace = var.namespace
            })
          ]

          env {
            name  = "PORTAINER_ADMIN_PASSWORD"
            value = var.portainer_admin_password
          }

          resources {
            requests = {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.portainer_service, kubernetes_service.registry_service]
}