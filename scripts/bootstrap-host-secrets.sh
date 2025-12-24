#!/usr/bin/env bash
set -euo pipefail

# Bootstrap secrets for a freshly installed host
# This script fetches the host's SSH key, converts it to age, updates sops.yaml,
# and re-encrypts secrets so the host can decrypt them.
#
# Usage: scripts/bootstrap-host-secrets.sh -n <hostname> -d <destination> [-p <port>] [-k <ssh_key>]

# Helpers library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

# User variables
target_hostname=""
target_destination=""
ssh_port=${BOOTSTRAP_SSH_PORT:-22}
ssh_key=${BOOTSTRAP_SSH_KEY:-}
git_root=$(git rev-parse --show-toplevel)

# Usage function
function help_and_exit() {
  echo
  echo "Bootstrap secrets for a freshly installed NixOS host."
  echo "Fetches the host's SSH key, converts to age, updates sops.yaml, and rekeys secrets."
  echo
  echo "USAGE: $0 -n <hostname> -d <destination> [OPTIONS]"
  echo
  echo "ARGS:"
  echo "  -n <hostname>       Name of the host in your flake (e.g., starcommand)"
  echo "  -d <destination>    IP or domain to SSH to (e.g., 192.168.0.102)"
  echo
  echo "OPTIONS:"
  echo "  -p <port>           SSH port (default: 22)"
  echo "  -k <ssh_key>        Path to SSH private key for authentication"
  echo "  --debug             Enable debug mode"
  echo "  -h | --help         Print this help"
  echo
  echo "EXAMPLES:"
  echo "  $0 -n starcommand -d 192.168.0.102"
  echo "  $0 -n starcommand -d 192.168.0.102 -p 2222"
  echo "  $0 -n starcommand -d 192.168.0.102 -k ~/.ssh/deploy_key"
  exit 0
}

# Handle command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  -n)
    shift
    target_hostname=$1
    ;;
  -d)
    shift
    target_destination=$1
    ;;
  -p)
    shift
    ssh_port=$1
    ;;
  -k)
    shift
    ssh_key=$1
    ;;
  --debug)
    set -x
    ;;
  -h | --help)
    help_and_exit
    ;;
  *)
    red "ERROR: Invalid option: $1"
    help_and_exit
    ;;
  esac
  shift
done

# Validate required options
if [ -z "$target_hostname" ] || [ -z "$target_destination" ]; then
  red "ERROR: -n and -d are required"
  help_and_exit
fi

cd "$FLAKE_ROOT"

# Build SSH command
ssh_opts="-oControlPath=none -oport=${ssh_port} -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
if [ -n "$ssh_key" ]; then
  ssh_opts="$ssh_opts -i $ssh_key"
fi
ssh_cmd="ssh $ssh_opts"

blue "=========================================="
blue "Bootstrap Secrets for: $target_hostname"
blue "SSH Target: root@$target_destination:$ssh_port"
blue "=========================================="
echo

# Step 1: Clear old known_hosts entries
green "Clearing old known_hosts entries for $target_destination..."
sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts 2>/dev/null || true

# Step 2: Add new host fingerprint
green "Adding SSH host fingerprint to ~/.ssh/known_hosts..."
ssh-keyscan -p "$ssh_port" "$target_destination" 2>/dev/null | grep -v '^#' >>~/.ssh/known_hosts || true

# Step 3: Fetch the host's SSH public key
green "Fetching SSH host key from $target_destination..."
target_key=$(ssh-keyscan -p "$ssh_port" -t ssh-ed25519 "$target_destination" 2>&1 | grep ssh-ed25519 | cut -f2- -d" ") || {
  red "Failed to get SSH key. Is the host up? Is SSH running on port $ssh_port?"
  exit 1
}

if [ -z "$target_key" ]; then
  red "Failed to fetch SSH host key"
  exit 1
fi

green "Got SSH host key: ${target_key:0:60}..."

# Step 4: Convert to age key
green "Converting SSH key to age key..."
host_age_key=$(echo "$target_key" | nix_develop ssh-to-age)

if [[ ! "$host_age_key" =~ ^age1 ]]; then
  red "The generated age key does not match expected format."
  yellow "Result: $host_age_key"
  yellow "Expected format: age1..."
  exit 1
fi

green "Age key: $host_age_key"

# Step 5: Update sops.yaml with the new age key
green "Updating sops.yaml with new host age key..."

# Check if key already exists
current_key=$(nix_develop yq eval ".keys[] | select(anchor == \"${target_hostname}_host\")" sops.yaml 2>/dev/null || true)

if [ "$current_key" = "$host_age_key" ]; then
  green "Age key in sops.yaml is already up to date!"
else
  if [ -n "$current_key" ]; then
    blue "Updating existing key for ${target_hostname}_host..."
    blue "Old: $current_key"
    blue "New: $host_age_key"
    nix_develop yq eval -i "(.keys[] | select(anchor == \"${target_hostname}_host\")) = \"$host_age_key\"" sops.yaml
  else
    yellow "Key ${target_hostname}_host not found in sops.yaml, adding it..."
    nix_develop yq eval -i ".keys += [\"$host_age_key\"] | .keys[-1] anchor = \"${target_hostname}_host\"" sops.yaml
  fi
  green "Updated sops.yaml"
fi

# Step 6: Save the host key to the hosts directory
green "Saving host key to hosts/$target_hostname/host_key.pub..."
echo "$target_key" >"hosts/$target_hostname/host_key.pub"

# Step 7: Re-encrypt (rekey) all secrets files that include this host
green "Re-encrypting secrets files with new host key..."

rekey_file() {
  local file=$1
  if [ -f "$file" ]; then
    blue "Rekeying $file..."
    SOPS_AGE_KEY_FILE=sops.key nix_develop sops --config sops.yaml updatekeys -y "$file" 2>&1 || {
      yellow "Warning: Failed to rekey $file (may not exist or have issues)"
    }
  fi
}

# Host secrets
rekey_file "hosts/$target_hostname/secrets.yaml"

# User secrets (if hostname matches a user)
rekey_file "users/$target_hostname/secrets.yaml"

# Also rekey any other files that might reference this host
# (based on sops.yaml creation rules that include this host)
for secrets_file in users/*/secrets.yaml; do
  if [ -f "$secrets_file" ]; then
    # Check if this file's creation rule includes our host
    if grep -q "${target_hostname}_host" sops.yaml; then
      rekey_file "$secrets_file"
    fi
  fi
done

echo
green "=========================================="
green "Bootstrap Complete!"
green "=========================================="
echo
blue "Files modified:"
echo "  - sops.yaml (updated ${target_hostname}_host age key)"
echo "  - hosts/$target_hostname/host_key.pub"
echo "  - Rekeyed relevant secrets.yaml files"
echo
blue "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit: git add -A && git commit -m 'Bootstrap secrets for $target_hostname'"
echo "  3. Deploy: just deploy $target_hostname"
echo
yellow "Note: The host should now be able to decrypt its secrets on next deployment."
