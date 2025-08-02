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
    
    # First, let's get the disk device from the NixOS configuration
    echo "🎯 Extracting target disk device from configuration..."
    target_disk=$(nix eval .#nixosConfigurations.$config_name.config.FTS-FLEET.system.disk.device 2>/dev/null | tail -1 | sed 's/^"//;s/"$//' || echo "")
    
    if [ -n "$target_disk" ]; then
        echo "✅ Target disk from NixOS config: $target_disk"
    else
        echo "⚠️  Could not extract disk device from NixOS config"
        echo "Trying alternative approach..."
        
        # Try to get it from the disko configuration
        target_disk=$(nix eval .#nixosConfigurations.$config_name.config.system.build.diskoScript --apply 'builtins.toString' 2>/dev/null | tail -1 | grep -o '/dev/[^[:space:]]*' | head -1 || echo "")
        
        if [ -n "$target_disk" ]; then
            echo "✅ Target disk from disko script: $target_disk"
        else
            echo "❌ Could not determine target disk"
            target_disk=""
        fi
    fi
    
    # Get the full disko configuration for display
    disko_config=$(nix eval .#nixosConfigurations.$config_name.config.system.build.diskoScript --apply 'builtins.toString' 2>/dev/null | tail -10 || echo "")
    
    if [ -n "$disko_config" ]; then
        echo "📋 Disko configuration found:"
        echo "$disko_config" | head -10
        echo "..."
    fi
    
    # Show current disk devices
    echo ""
    echo "💾 Current disk devices:"
    echo "========================"
    
    # Use lsblk if available, otherwise use diskutil (macOS) or df
    if command -v lsblk >/dev/null 2>&1; then
        lsblk -f
    elif command -v diskutil >/dev/null 2>&1; then
        echo "macOS detected, using diskutil:"
        diskutil list
    else
        echo "Using df to show mounted filesystems:"
        df -h
    fi
    
    echo ""
    echo "🔍 Disk device analysis:"
    echo "========================"
    
    if [ -n "$target_disk" ]; then
        echo "🎯 Target disk from configuration: $target_disk"
        
        # Check if the target disk exists
        if [ -b "$target_disk" ]; then
            echo "✅ Target disk exists: $target_disk"
            echo ""
            echo "📊 Disk details:"
            if command -v lsblk >/dev/null 2>&1; then
                lsblk "$target_disk" -f
            elif command -v diskutil >/dev/null 2>&1; then
                diskutil info "$target_disk" 2>/dev/null || echo "Could not get disk info"
            else
                ls -la "$target_disk" 2>/dev/null || echo "Could not access disk"
            fi
        else
            echo "❌ Target disk not found: $target_disk"
            echo ""
            echo "Available disks:"
            if command -v lsblk >/dev/null 2>&1; then
                lsblk | grep -E "^(NAME|sd|nvme|hd)"
            elif command -v diskutil >/dev/null 2>&1; then
                diskutil list | head -20
            else
                ls /dev/sd* /dev/nvme* 2>/dev/null || echo "No disk devices found"
            fi
        fi
    else
        echo "⚠️  Could not determine target disk from configuration"
        echo ""
        echo "Available disks:"
        if command -v lsblk >/dev/null 2>&1; then
            lsblk | grep -E "^(NAME|sd|nvme|hd)"
        elif command -v diskutil >/dev/null 2>&1; then
            diskutil list | head -20
        else
            ls /dev/sd* /dev/nvme* 2>/dev/null || echo "No disk devices found"
        fi
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