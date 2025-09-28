# Backend configuration for persistent state storage
# This ensures the Terraform state file persists across repository updates

terraform {
  backend "local" {
    path = "/home/homelab/tfstate/terraform.tfstate"
  }
}