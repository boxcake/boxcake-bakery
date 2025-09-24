# Registry UI for browsing Docker Registry

# Registry UI Deployment
resource "kubernetes_deployment" "registry_ui" {
  metadata {
    name      = "registry-ui"
    namespace = var.namespace

    labels = {
      app = "registry-ui"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "registry-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "registry-ui"
        }
      }

      spec {
        container {
          name  = "registry-ui"
          image = "joxit/docker-registry-ui:main"

          port {
            container_port = 80
            name           = "http"
          }

          env {
            name  = "REGISTRY_TITLE"
            value = "Home Lab Container Registry"
          }

          env {
            name  = "REGISTRY_URL"
            value = "http://registry-service:5000"
          }

          env {
            name  = "DELETE_IMAGES"
            value = tostring(var.allow_registry_deletion)
          }

          env {
            name  = "SHOW_CONTENT_DIGEST"
            value = "true"
          }

          env {
            name  = "NGINX_PROXY_PASS_URL"
            value = "http://registry-service:5000"
          }

          env {
            name  = "SHOW_CATALOG_NB_TAGS"
            value = "true"
          }

          env {
            name  = "CATALOG_MIN_BRANCHES"
            value = "1"
          }

          env {
            name  = "CATALOG_MAX_BRANCHES"
            value = "1"
          }

          env {
            name  = "TAGLIST_PAGE_SIZE"
            value = "100"
          }

          env {
            name  = "REGISTRY_SECURED"
            value = "false"
          }

          env {
            name  = "CATALOG_ELEMENTS_LIMIT"
            value = "1000"
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

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.registry_service]
}

# Registry UI LoadBalancer Service
resource "kubernetes_service" "registry_ui_service" {
  metadata {
    name      = "registry-ui-service"
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
      target_port = 80
    }

    selector = {
      app = "registry-ui"
    }
  }

  depends_on = [kubernetes_deployment.registry_ui]
}