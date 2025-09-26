# Conditional service deployment based on user configuration

# Create Portainer resources only if enabled
module "portainer" {
  source = "./modules/portainer"
  count  = var.enable_portainer ? 1 : 0

  namespace               = var.namespace
  portainer_storage_size  = var.portainer_storage_size
  portainer_image        = var.portainer_image
  metallb_pool_name      = var.metallb_pool_name
}

# Create Registry resources only if enabled
module "registry" {
  source = "./modules/registry"
  count  = var.enable_registry ? 1 : 0

  namespace            = var.namespace
  registry_storage_size = var.registry_storage_size
  registry_image       = var.registry_image
  registry_port        = var.registry_port
  metallb_pool_name    = var.metallb_pool_name
  allow_registry_deletion = var.allow_registry_deletion
}

# Create Registry UI resources only if enabled and registry is enabled
module "registry_ui" {
  source = "./modules/registry-ui"
  count  = var.enable_registry_ui && var.enable_registry ? 1 : 0

  namespace         = var.namespace
  registry_port     = var.registry_port
  metallb_pool_name = var.metallb_pool_name

  depends_on = [module.registry]
}