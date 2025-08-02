#!/bin/bash

# NixOS Quick Install Script
# For use from within the NixOS installer ISO

set -e

echo "🚀 NixOS Quick Install Script"
echo "=============================="
echo ""

# Function to get available configurations
get_available_configurations() {
    echo "📋 Available NixOS configurations:"
    echo "-----------------------------------"
    
    # Try to get configurations from the flake
    if [ -f "flake.nix" ]; then
        configs=$(nix eval --json .#nixosConfigurations --apply 'builtins.attrNames' 2>/dev/null | tail -1 || echo "[]")
        
        if [ "$configs" != "[]" ] && [ "$configs" != "" ]; then
            echo "$configs" | jq -r '.[]' | nl
        else
            echo "❌ No configurations found or flake evaluation failed"
            echo "💡 Make sure you're in the correct directory with your flake"
            exit 1
        fi
    else
        echo "❌ No flake.nix found in current directory"
        echo "💡 Please navigate to your NixOS configuration directory"
        exit 1
    fi
}

# Function to select configuration
select_configuration() {
    echo ""
    echo "🔧 Select a configuration to install:"
    echo "-------------------------------------"
    
    # Get configurations as array
    configs=($(nix eval --json .#nixosConfigurations --apply 'builtins.attrNames' 2>/dev/null | tail -1 | jq -r '.[]' || echo ""))
    
    if [ ${#configs[@]} -eq 0 ]; then
        echo "❌ No configurations available"
        exit 1
    fi
    
    # Show numbered list
    for i in "${!configs[@]}"; do
        echo "$((i+1)). ${configs[$i]}"
    done
    
    echo ""
    read -p "Enter the number of the configuration to install: " choice
    
    # Validate choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#configs[@]} ]; then
        echo "❌ Invalid choice. Please enter a number between 1 and ${#configs[@]}"
        exit 1
    fi
    
    selected_config="${configs[$((choice-1))]}"
    echo "✅ Selected: $selected_config"
}

# Function to verify disk
verify_disk() {
    local config_name="$1"
    
    echo ""
    echo "💾 Disk verification for: $config_name"
    echo "----------------------------------------"
    
    # Get the target disk from the configuration
    echo "📋 Evaluating target disk from configuration..."
    target_disk=$(nix eval .#nixosConfigurations.$config_name.config.FTS-FLEET.system.disk.device --apply 'builtins.toString' 2>/dev/null | tail -1 || echo "")
    
    if [ -z "$target_disk" ]; then
        echo "⚠️  Could not determine target disk from configuration"
        echo "💡 Will use nixos-anywhere's default disk selection"
    else
        echo "✅ Target disk: $target_disk"
    fi
    
    # Show current disk devices
    echo ""
    echo "📋 Current disk devices:"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk -f
    else
        df -h
    fi
    
    echo ""
    echo "⚠️  WARNING: This will completely erase and repartition the target disk!"
    echo "   All data on the target disk will be lost!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "❌ Installation cancelled"
        exit 0
    fi
}

# Function to run nixos-anywhere
run_nixos_anywhere() {
    local config_name="$1"
    
    echo ""
    echo "🔧 Installing NixOS configuration: $config_name"
    echo "============================================="
    
    echo "🚀 Running nixos-anywhere..."
    echo "   This will partition, format, and install NixOS automatically"
    echo ""
    
    # Run nixos-anywhere targeting localhost
    nix run github:nix-community/nixos-anywhere -- --flake .#$config_name --target-host root@127.0.0.1
    
    echo ""
    echo "✅ Installation completed!"
    echo "🔄 Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
}

# Main execution
main() {
    get_available_configurations
    select_configuration
    verify_disk "$selected_config"
    run_nixos_anywhere "$selected_config"
}

# Run main function
main "$@" 