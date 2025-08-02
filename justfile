# Justfile for nix-config management

# Run the main deployment script
run:
    @bash scripts/deploy.sh

# Run the deployment script directly
deploy:
    @bash scripts/deploy.sh

# Run the installation script
install:
    @bash scripts/install.sh

# Show help
default:
    @just --list

# Build the configuration
build:
    @nix build

# Switch to the configuration
switch:
    @sudo nixos-rebuild switch --flake .

# Test the configuration
test:
    @nix build --dry-run

# Format all files
fmt:
    @treefmt

# Check syntax
check:
    @nix flake check

# Show available commands
list:
    @just --list

# Run with debug mode
install-debug:
    @bash scripts/install.sh --debug

# Quick deployment to all hosts
deploy-all:
    @echo "Deploying to all hosts..."
    @cd deployments/nixos && NIXPKGS_ALLOW_UNFREE=1 nix-shell -p terraform --run "terraform apply -auto-approve" 