# NixOS Configuration Management
# Usage: just <command>

# Define path to helpers
export HELPERS_PATH := justfile_directory() + "/scripts/helpers.sh"

# Default target
default:
    @just --list

# Create a new module using the template
[no-cd]
module name:
    @echo "Creating new module: {{name}}"
    @mkdir -p {{name}}
    @cp $(git rev-parse --show-toplevel)/templates/module/default.nix {{name}}/default.nix
    @echo "Module created at: {{name}}/default.nix"
    @echo "Edit {{name}}/default.nix to customize your module"

# Terraform deployment commands
terraform-init:
    @echo "Initializing Terraform..."
    @cd deployments/nixos && NIXPKGS_ALLOW_UNFREE=1 terraform init

terraform-plan:
    @echo "Planning Terraform deployment..."
    @cd deployments/nixos && NIXPKGS_ALLOW_UNFREE=1 terraform plan

terraform-apply:
    @echo "Applying Terraform deployment..."
    @cd deployments/nixos && NIXPKGS_ALLOW_UNFREE=1 terraform apply -auto-approve

terraform-destroy:
    @echo "Destroying Terraform deployment..."
    @cd deployments/nixos && NIXPKGS_ALLOW_UNFREE=1 terraform destroy -auto-approve

terraform-output:
    @echo "Showing Terraform outputs..."
    @cd deployments/nixos && NIXPKGS_ALLOW_UNFREE=1 terraform output

# Evaluate a NixOS configuration
eval config:
    @echo "Evaluating configuration {{config}}..."
    @nix eval .#nixosConfigurations.{{config}}.config.system.build.toplevel

# Rebuild commands
# Rebuild current system using phoenix sync
rebuild:
    @echo "Rebuilding current system using phoenix sync..."
    @phoenix sync

# Deploy specific target using deploy-rs
deploy target *FLAGS:
    @echo "Deploying {{target}} using deploy-rs..."
    @nix run github:serokell/deploy-rs -- {{FLAGS}} .#{{target}}

# Deploy all targets using deploy-rs
deploy-all:
    @echo "Deploying all targets using deploy-rs..."
    @nix run github:serokell/deploy-rs .

# Build the configuration
build-config:
    @nix build

# Format all files
fmt:
    @treefmt

# Check syntax
check:
    @nix flake check

# Secrets management commands
# Generate a new age key
age-key:
    nix-shell -p age --run "age-keygen"

# Check if sops-nix activated successfully
check-sops:
    @scripts/check-sops.sh

# Edit secrets using SOPS
edit-secrets file:
    @echo "Editing secrets file: {{file}}"
    @nix-shell -p sops --run "cd secrets && sops {{file}}"

# Encrypt secrets files using SOPS
encrypt-secrets file:
    @echo "Encrypting secrets file: {{file}}"
    @nix-shell -p sops --run "cd secrets && sops -e sops/{{file}} > sops/{{file}}.enc && mv sops/{{file}}.enc sops/{{file}}"

# Update all keys in sops/*.yaml files to match the creation rules keys
rekey:
    nix-shell -p sops yq --run "cd secrets && for file in \$(ls sops/*.yaml); do sops updatekeys -y \$file; done"

# Update an age key anchor or add a new one
sops-update-age-key FIELD KEYNAME KEY:
    #!/usr/bin/env bash
    nix-shell -p sops yq --run "source {{HELPERS_PATH}} && sops_update_age_key {{FIELD}} {{KEYNAME}} {{KEY}}"

# Update an existing user age key anchor or add a new one
sops-update-user-age-key USER HOST KEY:
    just sops-update-age-key users {{USER}}_{{HOST}} {{KEY}}

# Update an existing host age key anchor or add a new one
sops-update-host-age-key HOST KEY:
    just sops-update-age-key hosts {{HOST}} {{KEY}}

# Automatically create creation rules entries for a <host>.yaml file for host-specific secrets
sops-add-host-creation-rules USER HOST:
    #!/usr/bin/env bash
    nix-shell -p sops yq --run "source {{HELPERS_PATH}} && sops_add_host_creation_rules \"{{USER}}\" \"{{HOST}}\""

# Automatically create creation rules entries for a shared.yaml file for shared secrets
sops-add-shared-creation-rules USER HOST:
    #!/usr/bin/env bash
    nix-shell -p sops yq --run "source {{HELPERS_PATH}} && sops_add_shared_creation_rules \"{{USER}}\" \"{{HOST}}\""

# Automatically add the host and user keys to creation rules for shared.yaml and <host>.yaml
sops-add-creation-rules USER HOST:
    just sops-add-host-creation-rules {{USER}} {{HOST}} && \
    just sops-add-shared-creation-rules {{USER}} {{HOST}}

# Bootstrap a NixOS system with SOPS setup (without full install)
bootstrap HOST_NAME HOST_IP SSH_KEY:
    @NIX_SECRETS_DIR=$(pwd)/secrets SOPS_CONFIG_DIR=$(pwd) GIT_ROOT=$(pwd) nix-shell -p age ssh-to-age sops --run "scripts/bootstrap-nixos.sh -n {{HOST_NAME}} -d {{HOST_IP}} -k {{SSH_KEY}}"

# Add a new host to existing SOPS setup
add-sops-host HOST_NAME HOST_IP SSH_KEY:
    @scripts/add-sops-host.sh {{HOST_NAME}} {{HOST_IP}} {{SSH_KEY}}

# Reset SOPS setup (cleans up for fresh start)
reset-sops:
    #!/usr/bin/env bash
    echo "🧹 Resetting SOPS setup..."
    
    # Remove age key directory
    rm -rf /home/cody/.config/sops/age
    
    # Remove secrets files (keep directory structure)
    rm -f secrets/sops/*.yaml
    rm -f secrets/.sops.yaml
    
    # Recreate empty sops directory
    mkdir -p secrets/sops
    
    echo "✅ SOPS reset complete. Run 'just setup-sops' to start fresh."

# Set up SOPS from scratch (automates the entire process)
setup-sops:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔐 Setting up SOPS secrets management..."
    
    # Step 1: Generate user age key
    echo "📝 Generating user age key..."
    USER_AGE_OUTPUT=$(nix-shell -p age --run "age-keygen")
    USER_SECRET_KEY=$(echo "$USER_AGE_OUTPUT" | grep "AGE-SECRET-KEY" | cut -d' ' -f2)
    USER_PUBLIC_KEY=$(echo "$USER_AGE_OUTPUT" | grep "public key:" | cut -d' ' -f4)
    
    # Step 2: Get host age key from SSH
    echo "🔑 Deriving host age key from SSH host key..."
    HOST_AGE_KEY=$(nix-shell -p ssh-to-age --run "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age")
    HOSTNAME=$(hostname)
    
    # Step 3: Create .sops.yaml configuration
    echo "📄 Creating .sops.yaml configuration..."
    cat > secrets/.sops.yaml << EOF
    # SOPS configuration for nix-config
    # Generated on $(date -I)
    
    # Public keys
    keys:
      users:
        - &cody ${USER_PUBLIC_KEY}
      hosts:
        - &${HOSTNAME} ${HOST_AGE_KEY}
    
    # Creation rules for different secret files
    creation_rules:
      # Shared secrets accessible by all users and hosts
      - path_regex: shared\.yaml\$
        key_groups:
          - age:
              - *cody
              - *${HOSTNAME}
      
      # Host-specific secrets for ${HOSTNAME}
      - path_regex: ${HOSTNAME}\.yaml\$
        key_groups:
          - age:
              - *${HOSTNAME}
              - *cody
    EOF
    
    # Step 4: Create initial secrets files
    echo "📋 Creating initial secrets files..."
    cat > secrets/sops/shared.yaml << EOF
    # Shared secrets accessible by all users and hosts
    # This file contains secrets that should be available across all systems
    
    # Cloudflare DNS API credentials for ACME DNS-01 challenges
    cloudflare:
      api_token: "your-cloudflare-api-token-here"
      zone_id: "your-cloudflare-zone-id-here"
    
    # User passwords for system creation
    passwords:
      cody: "your-encrypted-password-here"
      msmtp: "your-msmtp-password-here"
    
    # Other shared secrets can be added here
    EOF
    
    cat > secrets/sops/${HOSTNAME}.yaml << EOF
    # Host-specific secrets for ${HOSTNAME}
    # This file contains secrets specific to this host
    
    # SSH keys and other host-specific secrets
    keys:
      age: "${USER_SECRET_KEY}"
    
    # Host-specific passwords or other secrets
    # Example:
    # passwords:
    #   root: "encrypted-root-password-here"
    EOF
    
    # Step 5: Set up age key directory
    echo "🗂️  Setting up age key directory..."
    mkdir -p /home/cody/.config/sops/age
    echo "${USER_SECRET_KEY}" > /home/cody/.config/sops/age/keys.txt
    chmod 600 /home/cody/.config/sops/age/keys.txt
    chown -R cody:users /home/cody/.config/sops
    
    # Step 6: Encrypt the secrets files
    echo "🔒 Encrypting secrets files..."
    cd secrets
    nix-shell -p sops --run "sops -e sops/shared.yaml > sops/shared.yaml.enc && mv sops/shared.yaml.enc sops/shared.yaml"
    nix-shell -p sops --run "sops -e sops/${HOSTNAME}.yaml > sops/${HOSTNAME}.yaml.enc && mv sops/${HOSTNAME}.yaml.enc sops/${HOSTNAME}.yaml"
    cd ..
    
    # Step 7: Display completion message
    echo "✅ SOPS setup complete!"
    echo ""
    echo "📋 Summary:"
    echo "  - User age key: ${USER_PUBLIC_KEY}"
    echo "  - Host age key: ${HOST_AGE_KEY}"
    echo "  - Secrets files encrypted and ready"
    echo "  - Age key installed at: /home/cody/.config/sops/age/keys.txt"
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Edit secrets: just edit-secrets sops/shared.yaml"
    echo "  2. Enable SOPS modules in your system configuration"
    echo "  3. Add real credentials to replace placeholder values"
