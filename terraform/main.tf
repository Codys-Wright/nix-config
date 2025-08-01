terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Local variables for configuration
locals {
  # Instance ID for tracking reinstallations
  instance_id = var.instance_id != "" ? var.instance_id : "vm-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  
  # NixOS system attributes
  nixos_system_attr = ".#nixosConfigurations.vm.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.vm.config.system.build.diskoScript"
}

# Main deployment module using nixos-anywhere all-in-one
module "deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  
  # Target configuration
  target_host = var.target_host
  target_user = var.target_user
  target_port = var.target_port
  
  # NixOS system configuration
  nixos_system_attr      = local.nixos_system_attr
  nixos_partitioner_attr = local.nixos_partitioner_attr
  
  # Instance tracking for reinstallations
  instance_id = local.instance_id
  
  # Optional: Enable debug logging
  debug_logging = var.debug_logging
  
  # Optional: Build on remote machine instead of locally
  build_on_remote = var.build_on_remote
  
  # Optional: Custom phases
  phases = var.phases
  
  # Optional: Extra environment variables
  extra_environment = var.extra_environment
  
  # Optional: Special arguments passed to NixOS modules
  special_args = {
    # These will be available in your NixOS modules as specialArgs
    terraform = {
      target_host = var.target_host
      instance_id = local.instance_id
    }
  }
}

# Output the deployment result
output "deployment_result" {
  description = "Result of the NixOS deployment"
  value       = module.deploy.result
}

# Output target information
output "target_info" {
  description = "Target host information"
  value = {
    host = var.target_host
    user = var.target_user
    port = var.target_port
    instance_id = local.instance_id
  }
} 