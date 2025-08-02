terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

# Read the host configuration
locals {
  hosts = jsondecode(file("../../systems/x86_64-linux/THEBATTLESHIP/host.tf.json"))
}

# Deploy each host
module "deploy" {
  for_each = local.hosts

  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"

  # NixOS system configuration
  nixos_system_attr      = ".#nixosConfigurations.${each.value.hostname}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.value.hostname}.config.system.build.diskoScript"

  # Target configuration
  target_host = each.value.ipv4
  target_user = "root"
  target_port = 22

  # Instance ID for tracking reinstallations
  instance_id = each.value.ipv4

  # Build on remote to avoid signature issues
  build_on_remote = true

  # Debug logging for troubleshooting
  debug_logging = true

  # Phases to run
  phases = ["kexec", "disko", "install", "reboot"]

  # Extra environment variables
  extra_environment = {
    SSHPASS = each.value.install_password
  }
}

# Output the deployment results
output "deployments" {
  value = module.deploy
} 