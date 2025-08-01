terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

locals {
  host_files = fileset(".", "../../systems/**/**/host.tf.json")
  hosts = {
    for file in local.host_files :
    file => jsondecode(file(file))
  }
}

# Deploy to each host using null_resource with local-exec
resource "null_resource" "deploy" {
  for_each = local.hosts
  
  triggers = {
    instance_id = each.value.ipv4
    hostname    = each.value.hostname
  }
  
  provisioner "local-exec" {
    command = <<-EOF
      # Remove old host key if it exists
      ssh-keygen -R ${each.value.ipv4} 2>/dev/null || true
      
      # Run nixos-anywhere with password from environment
      SSHPASS="${each.value.install_password}" nix run github:nix-community/nixos-anywhere -- \
        --flake .#${each.value.hostname} \
        --target-host root@${each.value.ipv4} \
        --env-password
    EOF
    
    environment = {
      SSHPASS = each.value.install_password
    }
  }
} 