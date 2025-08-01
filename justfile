# NixOS Anywhere Deployment Justfile
# Usage: just <command>

# Default target
default:
    @just --list

# List all available commands
list:
    @just --list

# Generate documentation using Snowfall Frost
docs:
    @echo "Generating documentation with Snowfall Frost..."
    @nix run github:snowfallorg/frost#frost -- build $(pwd)
    @echo "Documentation generated in frost-docs/ directory"

# Generate documentation for a specific module
docs-module module:
    @echo "Generating documentation for module: {{module}}"
    @nix run github:snowfallorg/frost#frost -- generate $(pwd) --module {{module}}

# Generate all module documentation
docs-all:
    @echo "Generating documentation for all modules..."
    @nix run github:snowfallorg/frost#frost -- generate $(pwd) --all-modules

# Serve documentation locally
docs-serve:
    @echo "Serving documentation locally..."
    @cd frost-docs && python3 -m http.server 8000

# Create a new module using the template
[no-cd]
module name:
    @echo "Creating new module: {{name}}"
    @mkdir -p {{name}}
    @cp $(git rev-parse --show-toplevel)/templates/module/default.nix {{name}}/default.nix
    @echo "Module created at: {{name}}/default.nix"
    @echo "Edit {{name}}/default.nix to customize your module"

# Create a new lib module using the template
[no-cd]
lib name:
    @echo "Creating new lib module: {{name}}"
    @mkdir -p {{name}}
    @cp $(git rev-parse --show-toplevel)/templates/lib/default.nix {{name}}/default.nix
    @echo "Lib module created at: {{name}}/default.nix"
    @echo "Edit {{name}}/default.nix to customize your lib module"

# Set target IP
target_ip ip:
    @echo "Setting target IP to {{ip}}..."
    @echo "NIXOS_TARGET_IP={{ip}}" > .env
    @echo "Target IP set to: {{ip}}"

# Set target password
target_password password:
    @echo "Setting target password..."
    @echo "NIXOS_TARGET_PASSWORD={{password}}" >> .env
    @echo "Target password set"

# Set both IP and password
target ip password:
    @echo "Setting target IP and password..."
    @echo "NIXOS_TARGET_IP={{ip}}" > .env
    @echo "NIXOS_TARGET_PASSWORD={{password}}" >> .env
    @echo "Target IP set to: {{ip}}"
    @echo "Target password set"

# Initial installation using nixos-anywhere
nixos-anywhere target:
    @echo "Installing NixOS using nixos-anywhere for target {{target}}..."
    @if [ ! -f .env ]; then echo "Error: .env file not found. Run 'just target <ip> <password>' first"; exit 1; fi
    @nix-shell -p sshpass --run 'bash -c "source .env && SSHPASS=$NIXOS_TARGET_PASSWORD nix run github:nix-community/nixos-anywhere -- --flake .#{{target}} --generate-hardware-config nixos-facter ./facter.json --target-host root@$NIXOS_TARGET_IP --env-password"'

# Deploy configuration updates using deploy-rs
deploy node:
    @echo "Deploying configuration using deploy-rs to {{node}}..."
    @if [ ! -f .env ]; then echo "Error: .env file not found. Run 'just target <ip> <password>' first"; exit 1; fi
    @nix-shell -p sshpass --run 'bash -c "source .env && nix run github:serokell/deploy-rs .#{{node}}"'

# Deploy specific node using deploy-rs (alias for deploy)
deploy-node node:
    @echo "Deploying node {{node}} using deploy-rs..."
    @nix-shell -p sshpass --run "nix run github:serokell/deploy-rs .#{{node}}"

# Evaluate a NixOS configuration
eval config:
    @echo "Evaluating configuration {{config}}..."
    @nix eval .#nixosConfigurations.{{config}}.config.system.build.toplevel

# Test connection to target
test-connection:
    @echo "Testing connection to target..."
    @if [ ! -f .env ]; then echo "Error: .env file not found. Run 'just target <ip> <password>' first"; exit 1; fi
    @nix-shell -p sshpass --run "bash -c 'source .env && SSHPASS=\$NIXOS_TARGET_PASSWORD sshpass -e ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@\$NIXOS_TARGET_IP \"echo SSH connection successful!\"'"

# Connect to target via SSH
connect:
    @echo "Connecting to target..."
    @if [ ! -f .env ]; then echo "Error: .env file not found. Run 'just target <ip> <password>' first"; exit 1; fi
    @nix-shell -p sshpass --run "bash -c 'source .env && SSHPASS=\$NIXOS_TARGET_PASSWORD sshpass -e ssh -o StrictHostKeyChecking=no root@\$NIXOS_TARGET_IP'"

# Show current target configuration
show-config:
    @echo "Current target configuration:"
    @if [ -f .env ]; then \
        grep NIXOS_TARGET_IP .env | sed 's/export //'; \
        grep NIXOS_TARGET_PASSWORD .env | sed 's/export //'; \
    else \
        echo "No configuration set. Run 'just target <ip> <password>' first"; \
    fi

# Build configuration locally
build target:
    @echo "Building configuration locally for {{target}}..."
    nix build .#{{target}}

# Test configuration in VM
test-vm target:
    @echo "Testing configuration in VM for {{target}}..."
    nix run github:nix-community/nixos-anywhere -- --flake .#{{target}} --vm-test

# Quick setup for your specific target
setup-my-target:
    @echo "Setting up for your target (192.168.122.217)..."
    just target 192.168.122.217 breeze-crazily-pristine
    @echo "Now you can use:"
    @echo "  just deploy           - Deploy to your target"
    @echo "  just test-connection  - Test SSH connection"
    @echo "  just show-config      - Show current configuration"

# Help
help:
    @echo "NixOS Anywhere Deployment Commands:"
    @echo ""
    @echo "Module Creation:"
    @echo "  just module                    - Create new module in current directory"
    @echo ""
    @echo "Target Configuration:"
    @echo "  just target_ip <ip>           - Set target IP address"
    @echo "  just target_password <pass>   - Set target password"
    @echo "  just target <ip> <pass>       - Set both IP and password"
    @echo "  just show-config              - Show current configuration"
    @echo ""
    @echo "Deployment:"
    @echo "  just nixos-anywhere <target>  - Initial NixOS installation"
    @echo "  just deploy <node>            - Deploy configuration updates"
    @echo "  just deploy-node <node>       - Deploy to specific node (alias)"
    @echo "  just eval <config>            - Evaluate NixOS configuration"
    @echo "  just test-connection          - Test SSH connection"
    @echo "  just connect                  - Connect to target via SSH"
    @echo "  just build <target>           - Build configuration locally"
    @echo "  just test-vm <target>         - Test configuration in VM"
    @echo ""
    @echo "Quick Setup:"
    @echo "  just setup-my-target          - Setup for your specific target"
    @echo ""
    @echo "Example Usage:"
    @echo "  cd modules/nixos/services && just module  # Creates 'services' module"
    @echo "  cd modules/home/programs && just module   # Creates 'programs' module"
    @echo "  just target 192.168.1.100 mypassword"
    @echo "  just nixos-anywhere vm       # Initial installation"
    @echo "  just deploy                   # Configuration updates"
    @echo "  just connect" 