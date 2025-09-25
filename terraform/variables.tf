# Variables for Kubernetes resources

variable "namespace" {
  description = "Kubernetes namespace for deployments"
  type        = string
  default     = "default"
}

# Portainer Configuration
variable "portainer_admin_password" {
  description = "Admin password for Portainer"
  type        = string
  default     = "homelab123!"
  sensitive   = true
}

variable "portainer_image" {
  description = "Portainer container image"
  type        = string
  default     = "portainer/portainer-ce:2.33.2-alpine"
}

variable "portainer_storage_size" {
  description = "Storage size for Portainer persistent volume"
  type        = string
  default     = "2Gi"
}

variable "portainer_nodeport" {
  description = "NodePort for Portainer HTTP access"
  type        = number
  default     = 32090
}

variable "portainer_nodeport_https" {
  description = "NodePort for Portainer HTTPS access"
  type        = number
  default     = 32443
}

# Registry Configuration
variable "registry_image" {
  description = "Docker registry container image"
  type        = string
  default     = "registry:3.0"
}

variable "registry_port" {
  description = "External port for the Docker registry LoadBalancer"
  type        = number
  default     = 5000
}

variable "registry_storage_size" {
  description = "Storage size for registry persistent volume"
  type        = string
  default     = "10Gi"
}

variable "registry_ui_nodeport" {
  description = "NodePort for Registry UI access"
  type        = number
  default     = 32080
}

variable "allow_registry_deletion" {
  description = "Allow image deletion in Registry UI"
  type        = bool
  default     = true
}

# Network Configuration
variable "metallb_pool_name" {
  description = "MetalLB address pool name"
  type        = string
  default     = "homelab-services"
}