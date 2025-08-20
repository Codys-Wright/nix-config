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

# Discover all hosts
locals {
  host_files = fileset(".", "../../systems/**/**/host.tf.json")
  hosts = {
    for file in local.host_files :
    file => jsondecode(file(file))
  }
  
  # Filter hosts based on target_host variable
  target_hosts = var.target_host != "" ? {
    for file, host in local.hosts :
    file => host
    if host.hostname == var.target_host
  } : local.hosts
}

# Deploy to each host using the nixos-anywhere all-in-one module
module "deploy" {
  for_each = local.target_hosts
  source   = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  
  # with flakes
  nixos_system_attr      = ".#nixosConfigurations.${each.value.hostname}.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.${each.value.hostname}.config.system.build.diskoScript"
  # without flakes
  # file can use (pkgs.nixos []) function from nixpkgs
  #file                   = "${path.module}/../.."
  #nixos_system_attr      = "config.system.build.toplevel"
  #nixos_partitioner_attr = "config.system.build.diskoScript"

  target_host            = each.value.ipv4
  # when instance id changes, it will trigger a reinstall
  instance_id            = each.value.ipv4
  # useful if something goes wrong
  debug_logging          = true
  # build the closure on the remote machine instead of locally
  build_on_remote        = true
  
  # script is below
  # extra_files_script     = "${path.module}/decrypt-ssh-secrets.sh"
  # disk_encryption_key_scripts = [{
  #   path   = "/tmp/secret.key"
  #   # script is below
  #   script = "${path.module}/decrypt-zfs-key.sh"
  # }]
  # Optional, arguments passed to special_args here will be available from a NixOS module in this example the `terraform` argument:
  # { terraform, ... }: {
  #    networking.interfaces.enp0s3.ipv4.addresses = [{ address = terraform.ip;  prefixLength = 24; }];
  # }
  # Note that this will means that your NixOS configuration will always depend on terraform!
  # Skip to `Pass data persistently to the NixOS` for an alternative approach
  #special_args = {
  #  terraform = {
  #    ip = "192.0.2.0"
  #  }
  #}
}

# Output the deployment results
output "deployments" {
  value = module.deploy
} 