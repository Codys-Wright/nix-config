# NixOS Configuration Management
# Usage: just <command>

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

# Deploy specific target using terraform
deploy target:
    @echo "Deploying {{target}} using terraform..."
    @cd deployments/nixos && terraform apply -var="target_host={{target}}" -auto-approve

# Build the configuration
build-config:
    @nix build

# Format all files
fmt:
    @treefmt

# Check syntax
check:
    @nix flake check
