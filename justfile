# Switch to a specific host configuration
# Automatically detects NixOS or Darwin and uses the appropriate command
switch host:
    @if command -v nixos-rebuild >/dev/null 2>&1 || [ -f /etc/nixos/configuration.nix ]; then \
        echo "Switching to NixOS configuration: {{host}}"; \
        NIX_CONFIG="experimental-features = nix-command flakes" nix develop --extra-experimental-features 'nix-command flakes' --command bash -c "nh os switch 'path:.#' -H {{host}}"; \
    elif command -v darwin-rebuild >/dev/null 2>&1 || [ "$(uname -s)" = "Darwin" ]; then \
        echo "Switching to Darwin configuration: {{host}}"; \
        NIX_CONFIG="experimental-features = nix-command flakes" nix develop --extra-experimental-features 'nix-command flakes' --command bash -c "nh darwin switch 'path:.#' -H {{host}}"; \
    else \
        echo "Error: Could not detect NixOS or Darwin system"; \
        exit 1; \
    fi

# Build a host configuration without switching
# Automatically detects NixOS or Darwin and uses the appropriate command
build host:
    @if command -v nixos-rebuild >/dev/null 2>&1 || [ -f /etc/nixos/configuration.nix ]; then \
        echo "Building NixOS configuration: {{host}}"; \
        NIX_CONFIG="experimental-features = nix-command flakes" nix develop --extra-experimental-features 'nix-command flakes' --command bash -c "nh os build 'path:.#' -H {{host}}"; \
    elif command -v darwin-rebuild >/dev/null 2>&1 || [ "$(uname -s)" = "Darwin" ]; then \
        echo "Building Darwin configuration: {{host}}"; \
        NIX_CONFIG="experimental-features = nix-command flakes" nix develop --extra-experimental-features 'nix-command flakes' --command bash -c "nh darwin build 'path:.#' -H {{host}}"; \
    else \
        echo "Error: Could not detect NixOS or Darwin system"; \
        exit 1; \
    fi

# Build an ISO image for a NixOS host
# Usage: just iso dave
iso host:
    @echo "Building ISO image for {{host}}..."
    @nix build .#nixosConfigurations.{{host}}.config.system.build.isoImage
    @echo "ISO image built successfully!"
    @if [ -L result ]; then \
        echo "ISO location: $(readlink -f result)/iso/nixos.iso"; \
    else \
        echo "Build result: result/"; \
    fi

# Run a VM for a NixOS host
# Usage: just vm dave
# This launches a QEMU/KVM VM with your NixOS configuration
vm host:
    @echo "Launching VM for {{host}}..."
    @nix run .#vm-{{host}}

# Check VM CPU cores and memory (run this inside the VM)
# Usage: Inside the VM, run: nproc, lscpu, or free -h
vm-info:
    @echo "To check VM resources, run these commands inside the VM:"
    @echo "  nproc              # Show number of CPU cores"
    @echo "  lscpu              # Show detailed CPU information"
    @echo "  free -h            # Show memory usage"
    @echo "  cat /proc/cpuinfo  # Show detailed CPU info"

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

# Run flake checks/tests
test:
    @echo "Running flake checks..."
    nix flake check

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

# ============================================================================
# SOPS Secrets Management Commands
# ============================================================================

# Generate a new age key pair for SOPS
# Usage: just sops-gen-key [keys.txt]
sops-gen-key:
    @nix run .#sops-gen-key -- "''${@}"

# Get target host's public age key from SSH
# Usage: just sops-get-host-key <hostname> [port]
# Example: just sops-get-host-key myserver.com
# Example: just sops-get-host-key localhost 2222
sops-get-host-key host port:
    @nix run .#sops-get-host-key -- {{host}} {{port}}

# Generate a random secret (default 64 bytes)
# Usage: just sops-gen-secret [length]
# Example: just sops-gen-secret 128
sops-gen-secret:
    @nix run .#sops-gen-secret -- "''${@}"

# Edit secrets.yaml file
# Usage: just sops-edit [secrets.yaml]
# Set SOPS_AGE_KEY_FILE and SOPS_CONFIG_FILE env vars if needed
sops-edit:
    @nix run .#sops-edit -- "''${@}"

# Smart edit-secrets: finds and edits secrets.yaml for a given name
# Searches in both hosts/ and users/ directories
# Usage: just edit-secrets <name>
# Example: just edit-secrets THEBATTLESHIP
# Example: just edit-secrets cody
edit-secrets name:
    #!/usr/bin/env bash
    set -e
    cd /home/cody/.flake
    HOST_FILE="hosts/{{name}}/secrets.yaml"
    USER_FILE="users/{{name}}/secrets.yaml"
    
    HOST_EXISTS=0
    USER_EXISTS=0
    
    if [ -f "$HOST_FILE" ]; then
        HOST_EXISTS=1
    fi
    
    if [ -f "$USER_FILE" ]; then
        USER_EXISTS=1
    fi
    
    if [ "$HOST_EXISTS" -eq 1 ] && [ "$USER_EXISTS" -eq 1 ]; then
        echo "Found secrets in both locations:"
        echo "  1. Host: $HOST_FILE"
        echo "  2. User: $USER_FILE"
        echo ""
        echo "Which one do you want to edit? (1/2/both)"
        read -r choice
        case "$choice" in
            1)
                echo "Editing host secrets..."
                SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml "$HOST_FILE"
                ;;
            2)
                echo "Editing user secrets..."
                SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml "$USER_FILE"
                ;;
            both)
                echo "Editing host secrets first..."
                SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml "$HOST_FILE"
                echo ""
                echo "Editing user secrets..."
                SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml "$USER_FILE"
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    elif [ "$HOST_EXISTS" -eq 1 ]; then
        echo "Editing host secrets: $HOST_FILE"
        SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml "$HOST_FILE"
    elif [ "$USER_EXISTS" -eq 1 ]; then
        echo "Editing user secrets: $USER_FILE"
        SOPS_AGE_KEY_FILE=sops.key nix develop --command sops --config sops.yaml "$USER_FILE"
    else
        echo "Error: No secrets.yaml found for '{{name}}'"
        echo "Searched in:"
        echo "  - hosts/{{name}}/secrets.yaml"
        echo "  - users/{{name}}/secrets.yaml"
        exit 1
    fi

# View secrets.yaml file (decrypted, read-only)
# Usage: just sops-view [secrets.yaml]
sops-view:
    @nix run .#sops-view -- "''${@}"

# Generate a new host with SSH keys and secrets.yaml
# Usage: just new-host <hostname>
# Example: just new-host myserver
new-host hostname:
    @nix develop --command bash ./scripts/new-host.sh {{hostname}}

# Generate a new user with age keys and secrets.yaml
# Usage: just new-user <username>
# Example: just new-user alice
new-user username:
    @nix develop --command bash ./scripts/new-user.sh {{username}}

# Create initial sops.yaml configuration file
# Usage: just sops-init-config [sops.yaml] <your-public-key> [host-public-key]
# Example:
#   MY_KEY=$(grep '^public key:' keys.txt | awk '{print $3}')
#   just sops-init-config sops.yaml "$MY_KEY"
sops-init-config config my-key host-key:
    @nix run .#sops-init-config -- {{config}} {{my-key}} {{host-key}}

# Create initial encrypted secrets.yaml file
# Usage: just sops-init-secrets [secrets.yaml]
sops-init-secrets:
    @nix run .#sops-init-secrets -- "''${@}"

# Quick setup: Initialize SOPS from scratch
# This will:
#   1. Generate age key pair
#   2. Create sops.yaml config
#   3. Create initial secrets.yaml
# Usage: just sops-setup [hostname] [port]
# Example: just sops-setup myserver.com
# Check if sops-nix is running and activated correctly
check-sops:
    @./scripts/check-sops.sh

sops-setup host port:
    @echo "Setting up SOPS secrets management..."
    @echo ""
    @echo "Step 1: Generating age key pair..."
    @nix run .#sops-gen-key
    @echo ""
    @echo "Step 2: Getting your public key..."
    @MY_KEY=$$(grep '^public key:' keys.txt | awk '{print $$3}' || grep '^public key:' keys.txt | sed 's/^public key: //'); \
    if [ -z "$$MY_KEY" ]; then \
        echo "Error: Could not extract public key from keys.txt"; \
        exit 1; \
    fi; \
    echo "Your public key: $$MY_KEY"
    @echo ""
    @if [ -n "{{host}}" ]; then \
        echo "Step 3: Getting host public key from {{host}}:''${port:-22}..."; \
        HOST_KEY=$$(nix run .#sops-get-host-key -- {{host}} ''${port:-22}); \
        echo "Host public key: $$HOST_KEY"; \
        echo ""; \
        echo "Step 4: Creating sops.yaml..."; \
        nix run .#sops-init-config -- sops.yaml "$$MY_KEY" "$$HOST_KEY"; \
    else \
        echo "Step 3: Creating sops.yaml (no host key)..."; \
        nix run .#sops-init-config -- sops.yaml "$$MY_KEY"; \
    fi
    @echo ""
    @echo "Step 5: Creating initial secrets.yaml..."
    @nix run .#sops-init-secrets
    @echo ""
    @echo "✓ SOPS setup complete!"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Edit secrets.yaml: just sops-edit"
    @echo "  2. View secrets: just sops-view"
    @echo "  3. Generate random secrets: just sops-gen-secret"

# Generate hardware configuration using nixos-facter
# Usage: just generate-hardware <hostname>
# Example: just generate-hardware THEBATTLESHIP
# This will generate hosts/THEBATTLESHIP/facter.json
# If hostname is a remote host, it will SSH to it and run nixos-facter
# Note: nixos-facter must be run as root
generate-hardware hostname:
    #!/usr/bin/env bash
    set -e
    cd /home/cody/.flake
    
    if [ -z "{{hostname}}" ]; then
        echo "Error: Hostname is required"
        echo "Usage: just generate-hardware <hostname>"
        echo "Example: just generate-hardware THEBATTLESHIP"
        exit 1
    fi
    
    HOST_DIR="hosts/{{hostname}}"
    OUTPUT_FILE="$HOST_DIR/facter.json"
    
    if [ ! -d "$HOST_DIR" ]; then
        echo "Error: Host directory not found: $HOST_DIR"
        echo "Create it first: mkdir -p $HOST_DIR"
        exit 1
    fi
    
    echo "Generating hardware configuration for {{hostname}}..."
    echo "Output: $OUTPUT_FILE"
    echo ""
    echo "Note: nixos-facter must be run as root"
    echo ""
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "{{hostname}}" exit 2>/dev/null || \
       ssh -o ConnectTimeout=5 -o BatchMode=yes "root@{{hostname}}" exit 2>/dev/null; then
        echo "Detected remote host, generating via SSH..."
        # Try as regular user first, then root
        if ssh "{{hostname}}" "sudo nix run github:numtide/nixos-facter#nixos-facter -- -o /tmp/facter.json" 2>/dev/null; then
            scp "{{hostname}}:/tmp/facter.json" "$OUTPUT_FILE"
            ssh "{{hostname}}" "rm /tmp/facter.json"
        elif ssh "root@{{hostname}}" "nix run github:numtide/nixos-facter#nixos-facter -- -o /tmp/facter.json" 2>/dev/null; then
            scp "root@{{hostname}}:/tmp/facter.json" "$OUTPUT_FILE"
            ssh "root@{{hostname}}" "rm /tmp/facter.json"
        else
            echo "Error: Failed to generate hardware configuration on remote host"
            echo "Make sure you have sudo access or can SSH as root"
            exit 1
        fi
    else
        echo "Generating locally (assuming this is the target system)..."
        # Check if we're root, if not use sudo
        if [ "$EUID" -eq 0 ]; then
            nix run github:numtide/nixos-facter#nixos-facter -- -o "$OUTPUT_FILE"
        else
            sudo nix run github:numtide/nixos-facter#nixos-facter -- -o "$OUTPUT_FILE"
        fi
    fi
    
    # Verify the output is valid JSON
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        # Check if it's valid JSON (starts with { or [)
        if head -c 1 "$OUTPUT_FILE" | grep -q '[{\[]'; then
            echo "✓ Hardware configuration saved to $OUTPUT_FILE"
            echo ""
            echo "Next step: Reference it in your host configuration:"
            echo "  facter.reportPath = ./facter.json;"
        else
            echo "Error: Generated file doesn't appear to be valid JSON"
            echo "File contents:"
            head -20 "$OUTPUT_FILE"
            exit 1
        fi
    else
        echo "Error: Failed to generate hardware configuration"
        echo "Check the output above for errors"
        exit 1
    fi
