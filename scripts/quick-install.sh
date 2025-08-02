#!/usr/bin/env bash

set -e

echo "🚀 NixOS Quick Install Script"
echo "============================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Error: This script must be run from the nix-config directory"
    exit 1
fi

# Function to get available nixosConfigurations from the flake
get_available_configurations() {
    echo "Available NixOS configurations:"
    echo "================================"
    
    # Get all nixosConfigurations from the flake using a more robust approach
    echo "📋 Evaluating flake configurations..."
    
    # Try to get configurations with error handling
    configurations=$(nix eval .#nixosConfigurations --apply 'builtins.attrNames' 2>/dev/null | tail -1 || echo "[]")
    
    # If that fails, try a different approach
    if [ "$configurations" = "[]" ] || [ "$configurations" = "null" ] || [ -z "$configurations" ]; then
        echo "⚠️  First attempt failed, trying alternative approach..."
        configurations=$(nix eval --raw .#nixosConfigurations --apply 'builtins.attrNames' 2>/dev/null || echo "[]")
    fi
    
    if [ "$configurations" = "[]" ] || [ "$configurations" = "null" ] || [ -z "$configurations" ]; then
        echo "❌ No nixosConfigurations found in flake.nix"
        echo "Debug: configurations = '$configurations'"
        echo ""
        echo "💡 Try committing your changes first:"
        echo "   git add . && git commit -m 'WIP'"
        exit 1
    fi
    
    # Parse the configurations (they should be in format ["THEBATTLESHIP" "vm"])
    local config_count=0
    local configs=()
    
    # Extract configuration names from the array
    while IFS= read -r config; do
        # Remove quotes and clean up
        config_name=$(echo "$config" | sed 's/^"//;s/"$//')
        if [ -n "$config_name" ] && [ "$config_name" != "[" ] && [ "$config_name" != "]" ]; then
            config_count=$((config_count + 1))
            echo "$config_count) $config_name"
            configs+=("$config_name")
        fi
    done < <(echo "$configurations" | tr ' ' '\n' | grep -v '^[[]]$' | grep -v '^[]]$')
    
    if [ $config_count -eq 0 ]; then
        echo "❌ No valid configurations found"
        echo "Debug: configurations = '$configurations'"
        exit 1
    fi
    
    echo ""
    echo "Select a configuration to install (1-$config_count), or 'q' to quit:"
    
    # Read user selection
    while true; do
        read -p "Enter your choice: " choice
        
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "❌ Installation cancelled"
            exit 1
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$config_count" ]; then
            SELECTED_CONFIG="${configs[$((choice - 1))]}"
            break
        else
            echo "❌ Invalid choice. Please enter a number between 1 and $config_count, or 'q' to quit."
        fi
    done
}

# Function to verify disk configuration
verify_disk_configuration() {
    local config_name="$1"
    
    echo ""
    echo "🔍 Verifying disk configuration for: $config_name"
    echo "============================================="
    
    # Get the disko configuration for this host
    echo "📋 Evaluating disko configuration..."
    disko_config=$(nix eval --json .#nixosConfigurations.$config_name.config.system.build.diskoScript --apply 'builtins.toString' 2>/dev/null || echo "")
    
    if [ -z "$disko_config" ]; then
        echo "⚠️  Warning: Could not evaluate disko configuration for $config_name"
        echo "Proceeding without disk verification..."
        return 0
    fi
    
    # Extract the disk device from the disko configuration
    # This is a simplified approach - in practice, you might need more sophisticated parsing
    echo "📋 Disko configuration found:"
    echo "$disko_config" | head -20
    
    # Show current disk devices
    echo ""
    echo "💾 Current disk devices:"
    echo "========================"
    lsblk -f
    
    echo ""
    echo "🔍 Disk device analysis:"
    echo "========================"
    
    # Try to extract the target disk device from the configuration
    # This is a simplified approach - you might need to adjust based on your disko setup
    target_disk=$(echo "$disko_config" | grep -o '/dev/[^[:space:]]*' | head -1 || echo "")
    
    if [ -n "$target_disk" ]; then
        echo "🎯 Target disk from configuration: $target_disk"
        
        # Check if the target disk exists
        if [ -b "$target_disk" ]; then
            echo "✅ Target disk exists: $target_disk"
            echo ""
            echo "📊 Disk details:"
            lsblk "$target_disk" -f
        else
            echo "❌ Target disk not found: $target_disk"
            echo ""
            echo "Available disks:"
            lsblk | grep -E "^(NAME|sd|nvme|hd)"
        fi
    else
        echo "⚠️  Could not determine target disk from configuration"
        echo ""
        echo "Available disks:"
        lsblk | grep -E "^(NAME|sd|nvme|hd)"
    fi
    
    echo ""
    echo "⚠️  WARNING: This will format and install to the target disk!"
    echo "All data on the target disk will be lost!"
    echo ""
    
    # Prompt for confirmation
    while true; do
        read -p "Do you want to proceed with the installation? (yes/no): " confirm
        
        case $confirm in
            [Yy]es|[Yy])
                echo "✅ Proceeding with installation..."
                return 0
                ;;
            [Nn]o|[Nn])
                echo "❌ Installation cancelled"
                exit 1
                ;;
            *)
                echo "Please answer 'yes' or 'no'"
                ;;
        esac
    done
}

# Function to run nixos-install
run_nixos_install() {
    local config_name="$1"
    
    echo ""
    echo "🔧 Installing NixOS configuration: $config_name"
    echo "============================================="
    
    # Check if we're running as root
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  Warning: Not running as root. You may need to run with sudo."
        echo "Proceeding anyway..."
    fi
    
    # Run nixos-install
    echo "🚀 Running nixos-install..."
    sudo nixos-install --root /mnt --flake .#$config_name
    
    echo ""
    echo "✅ Installation completed!"
    echo "🔄 Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
}

# Main execution
echo ""
echo "Welcome to the NixOS Quick Install script!"
echo "This script will help you install NixOS using your flake configuration."
echo ""

# Get available configurations
get_available_configurations

# Verify disk configuration
verify_disk_configuration "$SELECTED_CONFIG"

# Run the installation
run_nixos_install "$SELECTED_CONFIG" 