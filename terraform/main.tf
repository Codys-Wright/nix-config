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
  # Find all host.tf.json files in the systems directory
  host_files = fileset(path.module, "../systems/**/host.tf.json")
  
  # Parse each host file and create a map
  hosts = {
    for file in local.host_files : file => jsondecode(file(file))
  }
}

# Main deployment module using nixos-anywhere all-in-one
module "deploy" {
  for_each = local.hosts
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  
  # Target configuration from host file
  target_host = each.value.ipv4
  target_user = "root"
  target_port = 22
  
  # NixOS system configuration using hostname
  nixos_system_attr = ".#nixosConfigurations.${each.value.hostname}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.value.hostname}.config.system.build.diskoScript"
  
  # Hardware config generation path
  nixos_generate_config_path = format("%s/hardware-configuration.nix", trimsuffix(each.key, "host.tf.json"))
  
  # Instance tracking for reinstallations (use IP address)
  instance_id = each.value.ipv4
  
  # Optional: Enable debug logging
  debug_logging = true
  
  # Optional: Build on remote machine instead of locally
  build_on_remote = false
  
  # Optional: Custom phases
  phases = ["kexec", "disko", "install", "reboot"]
  
  # Optional: Extra environment variables
  extra_environment = {
    # Add any extra environment variables here
  }
  
  # Optional: Special arguments passed to NixOS modules
  special_args = {
    # These will be available in your NixOS modules as specialArgs
    terraform = {
      target_host = each.value.ipv4
      instance_id = each.value.ipv4
      hostname = each.value.hostname
    }
  }
}

# Output the deployment results
output "deployment_results" {
  description = "Results of the NixOS deployments"
  value = {
    for k, v in module.deploy : k => v.result
  }
}

# Output target information
output "target_info" {
  description = "Target host information"
  value = {
    for k, v in local.hosts : k => {
      host = v.ipv4
      hostname = v.hostname
      user = "root"
      port = 22
      instance_id = v.ipv4
    }
  }
} 