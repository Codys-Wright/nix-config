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

# Variable to target specific host(s)
variable "target_host" {
  description = "Hostname to target (leave empty for all hosts)"
  type        = string
  default     = ""
}

# Discover all hosts from host directories
# Each host should have a host.tf.json file in its directory:
# hosts/<hostname>/host.tf.json
locals {
  # Find all host.tf.json files in host directories
  # Structure: hosts/<hostname>/host.tf.json
  host_files = fileset("${path.module}/../..", "hosts/*/host.tf.json")
  
  # Parse each host configuration file
  hosts = {
    for file in local.host_files :
    # Extract hostname from path: hosts/THEBATTLESHIP/host.tf.json -> THEBATTLESHIP
    basename(dirname(file)) => jsondecode(file("${path.module}/../../${file}"))
  }
  
  # Filter hosts based on target_host variable (if specified)
  target_hosts = var.target_host != "" ? {
    for hostname, host in local.hosts :
    hostname => host
    if host.hostname == var.target_host || hostname == var.target_host
  } : local.hosts
}

# Deploy to each host using the nixos-anywhere all-in-one module
module "deploy" {
  for_each = local.target_hosts
  source   = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  
 # with flakes - den exposes nixosConfigurations
  # Use path:../../ to reference the flake at project root
  file                   = "${path.module}/../.."
  nixos_system_attr      = "nixosConfigurations.${each.value.hostname}.config.system.build.toplevel"
  nixos_partitioner_attr = "nixosConfigurations.${each.value.hostname}.config.system.build.diskoScript"
  
  target_host            = each.value.ipv4
  # when instance id changes, it will trigger a reinstall
  instance_id            = each.value.ipv4
  # useful if something goes wrong
  debug_logging          = true
  # build the closure on the remote machine instead of locally
  build_on_remote        = true
  
  # SSH configuration (with defaults)
  target_user            = lookup(each.value, "ssh_user", "root")
  target_port            = lookup(each.value, "ssh_port", 22)
  install_user           = lookup(each.value, "install_user", "nixos")
  install_port           = lookup(each.value, "install_port", 22)
  
  # Password authentication (if provided)
  # Note: nixos-anywhere uses --env-password flag, so password should be set via environment
  # The install_password field in host.tf.json is for reference/documentation
  # You'll need to set NIXOS_ANYWHERE_PASSWORD environment variable when running terraform
}

# Output the deployment results
output "deployments" {
  value = module.deploy
}

