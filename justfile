# Switch to a specific host configuration
# Automatically detects NixOS or Darwin and uses the appropriate command
switch host:
    @if command -v nixos-rebuild >/dev/null 2>&1 || [ -f /etc/nixos/configuration.nix ]; then \
        echo "Switching to NixOS configuration: {{host}}"; \
        nh os switch 'path:.#' -H {{host}}; \
    elif command -v darwin-rebuild >/dev/null 2>&1 || [ "$(uname -s)" = "Darwin" ]; then \
        echo "Switching to Darwin configuration: {{host}}"; \
        nh darwin switch 'path:.#' -H {{host}}; \
    else \
        echo "Error: Could not detect NixOS or Darwin system"; \
        exit 1; \
    fi

# Build a host configuration without switching
# Automatically detects NixOS or Darwin and uses the appropriate command
build host:
    @if command -v nixos-rebuild >/dev/null 2>&1 || [ -f /etc/nixos/configuration.nix ]; then \
        echo "Building NixOS configuration: {{host}}"; \
        nh os build 'path:.#' -H {{host}}; \
    elif command -v darwin-rebuild >/dev/null 2>&1 || [ "$(uname -s)" = "Darwin" ]; then \
        echo "Building Darwin configuration: {{host}}"; \
        nh darwin build 'path:.#' -H {{host}}; \
    else \
        echo "Error: Could not detect NixOS or Darwin system"; \
        exit 1; \
    fi

# Show available hosts
hosts:
    nix eval ".#darwinConfigurations" --apply "builtins.attrNames" --json

# Show available NixOS hosts
hosts-nixos:
    nix eval ".#nixosConfigurations" --apply "builtins.attrNames" --json

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

# Enter default development shell
dev:
    nix develop

# Enter deploy development shell (with Terraform)
dev-deploy:
    nix develop .#deploy

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
