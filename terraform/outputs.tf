# Output values for the deployed resources

# Portainer Service Information
output "portainer_loadbalancer_ip" {
  description = "LoadBalancer IP address for Portainer"
  value       = try(kubernetes_service.portainer_service.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "portainer_service_name" {
  description = "Kubernetes service name for Portainer"
  value       = kubernetes_service.portainer_service.metadata[0].name
}

# Registry UI Service Information
output "registry_ui_loadbalancer_ip" {
  description = "LoadBalancer IP address for Registry UI"
  value       = try(kubernetes_service.registry_ui_service.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "registry_ui_service_name" {
  description = "Kubernetes service name for Registry UI"
  value       = kubernetes_service.registry_ui_service.metadata[0].name
}

# Access Information
output "portainer_urls" {
  description = "Access URLs for Portainer"
  value = {
    loadbalancer_http  = "http://${try(kubernetes_service.portainer_service.status[0].load_balancer[0].ingress[0].ip, "pending")}"
    loadbalancer_https = "https://${try(kubernetes_service.portainer_service.status[0].load_balancer[0].ingress[0].ip, "pending")}"
    nodeport_http      = "http://${var.host_ip}:${var.portainer_nodeport}"
    nodeport_https     = "https://${var.host_ip}:${var.portainer_nodeport_https}"
  }
}

output "registry_ui_urls" {
  description = "Access URLs for Registry UI"
  value = {
    loadbalancer = "http://${try(kubernetes_service.registry_ui_service.status[0].load_balancer[0].ingress[0].ip, "pending")}"
    nodeport     = "http://${var.host_ip}:${var.registry_ui_nodeport}"
  }
}

# Configuration Information
output "portainer_admin_credentials" {
  description = "Portainer admin login information"
  value = {
    username = "admin"
    password = var.portainer_admin_password
  }
  sensitive = true
}

output "registry_info" {
  description = "Container registry information"
  value = {
    url  = "${var.host_ip}:${var.registry_port}"
    push_example = "docker push ${var.host_ip}:${var.registry_port}/my-image:tag"
  }
}

# Deployment Status
output "deployment_status" {
  description = "Status of all deployments"
  value = {
    portainer_ready   = kubernetes_deployment.portainer.status[0].ready_replicas > 0
    registry_ui_ready = kubernetes_deployment.registry_ui.status[0].ready_replicas > 0
  }
}