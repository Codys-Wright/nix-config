terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variable to target specific host(s)
variable "target_host" {
  description = "Hostname to target (leave empty for all hosts)"
  type        = string
  default     = ""
}

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

# Deploy to each host using null_resource with local-exec
resource "null_resource" "deploy" {
  for_each = local.target_hosts
  
  triggers = {
    instance_id = each.value.ipv4
    hostname    = each.value.hostname
  }
  
  provisioner "local-exec" {
    command = <<-EOF
      # Remove old host key if it exists
      ssh-keygen -R ${each.value.ipv4} 2>/dev/null || true
      
      # Extract disk device from NixOS configuration
      DISK_DEVICE=$(nix eval .#nixosConfigurations.${each.value.hostname}.config.${namespace}.system.disk.device --raw)
      
      # Run nixos-anywhere with password from environment
      SSHPASS="${each.value.install_password}" nix run github:nix-community/nixos-anywhere -- \
        --flake .#${each.value.hostname} \
        --target-host root@${each.value.ipv4} \
        --env-password \
        --disk "$DISK_DEVICE"
    EOF
    
    environment = {
      SSHPASS = each.value.install_password
    }
  }
} 