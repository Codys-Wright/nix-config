#!/usr/bin/env bash
set -euo pipefail

# Helpers library
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

HOST_NAME="$1"
HOST_IP="$2"

echo "🔐 Adding new host ${HOST_NAME} to SOPS setup..."

# Get host age key from SSH
echo "🔑 Getting host age key from ${HOST_NAME} (${HOST_IP})..."
HOST_AGE_KEY=$(ssh root@"${HOST_IP}" "cat /etc/ssh/ssh_host_ed25519_key.pub" | nix-shell -p ssh-to-age --run "ssh-to-age")

# Update .sops.yaml to add the new host using helper function
echo "📄 Updating .sops.yaml with new host..."
sops_update_age_key "hosts" "${HOST_NAME}" "${HOST_AGE_KEY}"

# Create host-specific secrets file
echo "📋 Creating host-specific secrets file..."
cat > secrets/sops/"${HOST_NAME}".yaml << EOF
# Host-specific secrets for ${HOST_NAME}
# This file contains secrets specific to this host

# SSH keys and other host-specific secrets
keys:
  age: "placeholder-will-be-set-by-nixos-module"

# Host-specific passwords or other secrets
passwords:
  cody: "password"
EOF

# Add creation rules for the new host
echo "📋 Adding creation rules for ${HOST_NAME}..."
sops_add_creation_rules "cody" "${HOST_NAME}"

# Encrypt the new host file
echo "🔒 Encrypting host-specific secrets file..."
cd secrets
nix-shell -p sops --run "sops -e sops/${HOST_NAME}.yaml > sops/${HOST_NAME}.yaml.enc && mv sops/${HOST_NAME}.yaml.enc sops/${HOST_NAME}.yaml"
cd ..

# Update existing secrets with new key
echo "🔄 Updating existing secrets with new host key..."
cd "$(dirname "${BASH_SOURCE[0]}")/.."
nix-shell -p sops yq --run "cd secrets && for file in \$(ls sops/*.yaml); do sops updatekeys -y \$file; done"

echo "✅ Host ${HOST_NAME} added to SOPS setup!"
echo "📋 Host age key: ${HOST_AGE_KEY}" 