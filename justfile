# Switch to a specific host configuration
switch host:
    nh darwin switch 'path:.#' -H {{host}}

# Build a host configuration without switching
build host:
    nh darwin build 'path:.#' -H {{host}}

# Show available hosts
hosts:
    nix eval ".#darwinConfigurations" --apply "builtins.attrNames" --json

# Show available home configurations
homes:
    nix eval ".#homeConfigurations" --apply "builtins.attrNames" --json

# Format code
fmt:
    nix run ".#fmt"

# Regenerate flake.nix from flake-file
write-flake:
    nix run ".#write-flake"

# Update flake.lock
update:
    nix flake update

# Show flake structure
show:
    nix flake show

# Enter development shell
dev:
    nix develop

# Terraform deployment commands
# Note: Terraform runs from project root to access the flake, using -chdir for config
# Uses nix-shell to provide terraform with required plugins
terraform-init:
    @echo "Initializing Terraform..."
    @NIXPKGS_ALLOW_UNFREE=1 nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [ (terraform.withPlugins (p: [ p.null p.external ])) ]; }' --run "terraform -chdir=deployments/nixos init"

terraform-plan:
    @echo "Planning Terraform deployment..."
    @NIXPKGS_ALLOW_UNFREE=1 nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [ (terraform.withPlugins (p: [ p.null p.external ])) ]; }' --run "terraform -chdir=deployments/nixos plan"

terraform-apply:
    @echo "Applying Terraform deployment..."
    @NIXPKGS_ALLOW_UNFREE=1 nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [ (terraform.withPlugins (p: [ p.null p.external ])) ]; }' --run "terraform -chdir=deployments/nixos apply -auto-approve"

terraform-apply-host host:
    @echo "Applying Terraform deployment to {{host}}..."
    @NIXPKGS_ALLOW_UNFREE=1 nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [ (terraform.withPlugins (p: [ p.null p.external ])) ]; }' --run "terraform -chdir=deployments/nixos apply -var='target_host={{host}}' -auto-approve"

terraform-destroy:
    @echo "Destroying Terraform deployment..."
    @NIXPKGS_ALLOW_UNFREE=1 nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [ (terraform.withPlugins (p: [ p.null p.external ])) ]; }' --run "terraform -chdir=deployments/nixos destroy -auto-approve"

terraform-output:
    @echo "Showing Terraform outputs..."
    @NIXPKGS_ALLOW_UNFREE=1 nix-shell -E 'with import <nixpkgs> {}; mkShell { buildInputs = [ (terraform.withPlugins (p: [ p.null p.external ])) ]; }' --run "terraform -chdir=deployments/nixos output"
