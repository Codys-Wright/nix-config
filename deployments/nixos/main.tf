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
  host = jsondecode(file("../../systems/x86_64-linux/THEBATTLESHIP/host.tf.json"))
}

# Deploy using nixos-anywhere directly
resource "null_resource" "deploy" {
  triggers = {
    instance_id = local.host.ipv4
    hostname    = local.host.hostname
  }
  
  provisioner "local-exec" {
    command = <<-EOF
      # Remove old host key if it exists
      ssh-keygen -R ${local.host.ipv4} 2>/dev/null || true
      
      # Run nixos-anywhere with build-on-remote and env-password
      nix run github:nix-community/nixos-anywhere -- \
        --flake .#${local.host.hostname} \
        --target-host root@${local.host.ipv4} \
        --build-on-remote \
        --env-password
    EOF
    
    environment = {
      SSHPASS = local.host.install_password
    }
  }
} 