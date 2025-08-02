#!/usr/bin/env bash

set -e

echo "🚀 THEBATTLESHIP NixOS Installer"
echo "=================================="

# Check if we're running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Git is required but not installed"
    exit 1
fi

# Configuration
REPO_URL="https://github.com/Codys-Wright/dotfiles.git"
FLAKE_HOST="THEBATTLESHIP"

# Check for debug mode
DEBUG_MODE=false
if [[ "$1" == "--debug" ]]; then
    DEBUG_MODE=true
    shift  # Remove --debug from arguments
    echo "🐛 DEBUG MODE ENABLED - No actual changes will be made"
    echo ""
fi

# Function to get available disks
get_available_disks() {
    echo "Available disks:"
    echo "================"
    local disk_count=0
    local disks=()

    # Get disk information
    while IFS= read -r line; do
        if [[ $line =~ ^(nvme|sd|hd)[a-z]+ ]]; then
            disk_count=$((disk_count + 1))
            disk_name=$(echo "$line" | awk '{print $1}')
            disk_size=$(echo "$line" | awk '{print $2}')
            disk_type=$(echo "$line" | awk '{print $3}')

            echo "$disk_count) $disk_name ($disk_size, $disk_type)"
            disks+=("$disk_name")
        fi
    done < <(lsblk -d -o NAME,SIZE,TYPE | grep -E "^(NAME|nvme|sd|hd)")

    echo ""
    echo "Select a disk to install to (1-$disk_count), or 'q' to quit:"

    # Read user selection
    while true; do
        read -p "Enter your choice: " choice

        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "❌ Installation cancelled"
            exit 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$disk_count" ]; then
            TARGET_DISK="${disks[$((choice - 1))]}"
            break
        else
            echo "❌ Invalid choice. Please enter a number between 1 and $disk_count, or 'q' to quit."
        fi
    done
}

# Get target disk from command line argument or use interactive selection
if [ -n "$1" ]; then
    TARGET_DISK="$1"
    echo "📋 Using specified disk: $TARGET_DISK"
else
    echo "📋 No disk specified. Starting interactive disk selection..."
    echo ""
    get_available_disks
fi

echo ""
echo "📋 Configuration:"
echo "  Repository: $REPO_URL"
echo "  Host: $FLAKE_HOST"
echo "  Target Disk: $TARGET_DISK"
echo ""

# Show disk details
echo "📊 Disk Details:"
echo "================"
lsblk "$TARGET_DISK" -o NAME,SIZE,TYPE,MOUNTPOINT
echo ""

# Confirm before proceeding
read -p "⚠️  This will ERASE the disk $TARGET_DISK. Are you sure? (type 'YES' to continue): " confirm
if [ "$confirm" != "YES" ]; then
    echo "❌ Installation cancelled"
    exit 1
fi

echo ""
echo "🔧 Installing NixOS..."

# Install Nix if not present
if ! command -v nix &> /dev/null; then
    if [ "$DEBUG_MODE" = true ]; then
        echo "🐛 [DEBUG] Would install Nix..."
        echo "   Command: sh <(curl -L https://nixos.org/nix/install) --daemon"
    else
        echo "📦 Installing Nix..."
        sh <(curl -L https://nixos.org/nix/install) --daemon
        source /etc/profile.d/nix.sh
    fi
fi

# Enable flakes
if [ "$DEBUG_MODE" = true ]; then
    echo "🐛 [DEBUG] Would enable flakes..."
    echo "   Command: mkdir -p /etc/nix"
    echo "   Command: echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf"
else
    mkdir -p /etc/nix
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
fi

# Clone the repository
if [ "$DEBUG_MODE" = true ]; then
    echo "🐛 [DEBUG] Would clone repository..."
    echo "   Command: cd /tmp"
    echo "   Command: rm -rf dotfiles"
    echo "   Command: git clone $REPO_URL dotfiles"
    echo "   Command: cd dotfiles"
else
    echo "📥 Cloning configuration repository..."
    cd /tmp
    rm -rf dotfiles
    git clone "$REPO_URL" dotfiles
    cd dotfiles
fi

# Run nixos-anywhere
if [ "$DEBUG_MODE" = true ]; then
    echo "🐛 [DEBUG] Would run nixos-anywhere..."
    echo "   Command: nix run github:nix-community/nixos-anywhere -- --flake .#$FLAKE_HOST $TARGET_DISK"
    echo ""
    echo "🐛 [DEBUG] Would reboot..."
    echo "   Command: sleep 10"
    echo "   Command: reboot"
else
    echo "🚀 Installing NixOS with THEBATTLESHIP configuration..."
    nix run github:nix-community/nixos-anywhere -- --flake .#$FLAKE_HOST "$TARGET_DISK"

    echo ""
    echo "✅ Installation complete!"
    echo "🔄 Rebooting in 10 seconds..."
    sleep 10
    reboot
fi

if [ "$DEBUG_MODE" = true ]; then
    echo ""
    echo "🐛 DEBUG MODE COMPLETE - No actual changes were made"
fi 