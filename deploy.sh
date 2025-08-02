#!/bin/bash

set -e

echo "🚀 NixOS Deployment Script"
echo "=========================="

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "❌ Error: This script must be run from the nix-config directory"
    exit 1
fi

# Function to get available hosts from Terraform
get_available_hosts() {
    echo "Available hosts:"
    echo "================"
    
    # Find all host.tf.json files
    host_files=$(find systems -name "host.tf.json" 2>/dev/null || true)
    
    if [ -z "$host_files" ]; then
        echo "❌ No host.tf.json files found in systems/ directory"
        exit 1
    fi
    
    local host_count=0
    local hosts=()
    
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            host_count=$((host_count + 1))
            
            # Extract hostname and IP from the JSON file
            hostname=$(jq -r '.hostname' "$file" 2>/dev/null || echo "unknown")
            ipv4=$(jq -r '.ipv4' "$file" 2>/dev/null || echo "unknown")
            
            # Get the system name from the path
            system_name=$(echo "$file" | sed 's|systems/.*/\([^/]*\)/host.tf.json|\1|')
            
            echo "$host_count) $system_name (hostname: $hostname, IP: $ipv4)"
            hosts+=("$system_name")
        fi
    done <<< "$host_files"
    
    echo ""
    echo "Select a host to deploy to (1-$host_count), or 'q' to quit:"
    
    # Read user selection
    while true; do
        read -p "Enter your choice: " choice
        
        if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            echo "❌ Deployment cancelled"
            exit 1
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$host_count" ]; then
            SELECTED_HOST="${hosts[$((choice - 1))]}"
            break
        else
            echo "❌ Invalid choice. Please enter a number between 1 and $host_count, or 'q' to quit."
        fi
    done
}

# Function to run Terraform deployment
run_terraform_deploy() {
    local target_host="$1"
    
    echo ""
    echo "🔧 Deploying to $target_host..."
    echo "================================"
    
    # Check if Terraform is initialized
    if [ ! -d "deployments/nixos/.terraform" ]; then
        echo "📦 Initializing Terraform..."
        cd deployments/nixos
        nix-shell -p terraform --run "terraform init"
        cd ../..
    fi
    
    # Run Terraform apply with target host
    echo "🚀 Running Terraform deployment..."
    cd deployments/nixos
    nix-shell -p terraform --run "terraform apply -var=\"target_host=$target_host\" -auto-approve"
    cd ../..
    
    echo ""
    echo "✅ Deployment to $target_host completed!"
}

# Function to show deployment options
show_deployment_options() {
    echo ""
    echo "Deployment Options:"
    echo "==================="
    echo "1) Deploy to specific host (interactive)"
    echo "2) Deploy to all hosts"
    echo "3) Show current Terraform state"
    echo "4) Exit"
    echo ""
    
    read -p "Select an option (1-4): " option
    
    case $option in
        1)
            get_available_hosts
            run_terraform_deploy "$SELECTED_HOST"
            ;;
        2)
            echo ""
            echo "🚀 Deploying to ALL hosts..."
            cd deployments/nixos
            nix-shell -p terraform --run "terraform apply -auto-approve"
            cd ../..
            echo "✅ Deployment to all hosts completed!"
            ;;
        3)
            echo ""
            echo "📊 Current Terraform state:"
            cd deployments/nixos
            nix-shell -p terraform --run "terraform show"
            cd ../..
            ;;
        4)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please select 1-4."
            show_deployment_options
            ;;
    esac
}

# Main execution
echo ""
echo "Welcome to the NixOS deployment script!"
echo "This script will help you deploy your NixOS configuration to your hosts."
echo ""

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed"
    echo "Install it with: nix-shell -p jq"
    exit 1
fi

# Show deployment options
show_deployment_options 