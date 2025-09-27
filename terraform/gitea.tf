# Gitea Git Server

# Persistent Volume Claim for Gitea data
resource "kubernetes_persistent_volume_claim" "gitea_pvc" {
  count = var.enable_gitea ? 1 : 0

  metadata {
    name      = "gitea-pvc"
    namespace = var.namespace

    labels = {
      app = "gitea"
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"

    resources {
      requests = {
        storage = var.gitea_storage_size
      }
    }
  }
}

# Service Account for Gitea
resource "kubernetes_service_account" "gitea_sa" {
  count = var.enable_gitea ? 1 : 0

  metadata {
    name      = "gitea-sa"
    namespace = var.namespace
  }
}

# Gitea Deployment
resource "kubernetes_deployment" "gitea" {
  count = var.enable_gitea ? 1 : 0

  metadata {
    name      = "gitea"
    namespace = var.namespace

    labels = {
      app = "gitea"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "gitea"
      }
    }

    template {
      metadata {
        labels = {
          app = "gitea"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.gitea_sa[0].metadata[0].name

        security_context {
          fs_group = 1000
        }

        container {
          name  = "gitea"
          image = var.gitea_image

          port {
            container_port = 3000
            name           = "http"
          }

          port {
            container_port = 22
            name           = "ssh"
          }

          volume_mount {
            name       = "gitea-data"
            mount_path = "/data"
          }

          env {
            name  = "GITEA__database__DB_TYPE"
            value = "sqlite3"
          }

          env {
            name  = "GITEA__database__PATH"
            value = "/data/gitea/gitea.db"
          }

          env {
            name  = "GITEA__server__DOMAIN"
            value = "gitea.local"
          }

          env {
            name  = "GITEA__server__SSH_DOMAIN"
            value = "gitea.local"
          }

          env {
            name  = "GITEA__server__ROOT_URL"
            value = "http://gitea.local/"
          }

          env {
            name  = "GITEA__security__INSTALL_LOCK"
            value = "true"
          }

          env {
            name  = "GITEA__security__SECRET_KEY"
            value = "changeme-secret-key-for-homelab"
          }

          env {
            name  = "GITEA__service__DISABLE_REGISTRATION"
            value = "true"
          }

          env {
            name  = "GITEA__service__REQUIRE_SIGNIN_VIEW"
            value = "false"
          }

          env {
            name  = "GITEA__admin__USERNAME"
            value = var.gitea_admin_username
          }

          env {
            name  = "GITEA__admin__PASSWORD"
            value = var.gitea_admin_password
          }

          env {
            name  = "GITEA__admin__EMAIL"
            value = var.gitea_admin_email
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "200m"
            }
            limits = {
              memory = "512Mi"
              cpu    = "500m"
            }
          }

          security_context {
            run_as_user = 1000
            run_as_group = 1000
          }

          liveness_probe {
            http_get {
              path = "/api/healthz"
              port = 3000
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/api/healthz"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }

        volume {
          name = "gitea-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.gitea_pvc[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Gitea LoadBalancer Service
resource "kubernetes_service" "gitea_service" {
  count = var.enable_gitea ? 1 : 0

  metadata {
    name      = "gitea-service"
    namespace = var.namespace

    annotations = {
      "kubelish/service-name" = "gitea"
      "kubelish/service-type" = "_gitea._tcp"
      "kubelish/txt" = "Gitea Git server and web interface"
      "metallb.io/address-pool" = var.metallb_pool_name
    }
  }

  spec {
    type = "LoadBalancer"

    port {
      name        = "http"
      port        = 80
      target_port = 3000
    }

    port {
      name        = "ssh"
      port        = 22
      target_port = 22
    }

    selector = {
      app = "gitea"
    }
  }

  depends_on = [kubernetes_deployment.gitea]
}