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
deploy target:
    @echo "Deploying {{target}} using deploy-rs..."
    @nix run github:serokell/deploy-rs .#{{target}}

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
    scripts/check-sops.sh

# Update all keys in sops/*.yaml files to match the creation rules keys
rekey:
    cd secrets && for file in $(ls sops/*.yaml); do \
        sops updatekeys -y $file; \
    done

# Update an age key anchor or add a new one
sops-update-age-key FIELD KEYNAME KEY:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_update_age_key {{FIELD}} {{KEYNAME}} {{KEY}}

# Update an existing user age key anchor or add a new one
sops-update-user-age-key USER HOST KEY:
    just sops-update-age-key users {{USER}}_{{HOST}} {{KEY}}

# Update an existing host age key anchor or add a new one
sops-update-host-age-key HOST KEY:
    just sops-update-age-key hosts {{HOST}} {{KEY}}

# Automatically create creation rules entries for a <host>.yaml file for host-specific secrets
sops-add-host-creation-rules USER HOST:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_add_host_creation_rules "{{USER}}" "{{HOST}}"

# Automatically create creation rules entries for a shared.yaml file for shared secrets
sops-add-shared-creation-rules USER HOST:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_add_shared_creation_rules "{{USER}}" "{{HOST}}"

# Automatically add the host and user keys to creation rules for shared.yaml and <host>.yaml
sops-add-creation-rules USER HOST:
    just sops-add-host-creation-rules {{USER}} {{HOST}} && \
    just sops-add-shared-creation-rules {{USER}} {{HOST}}
