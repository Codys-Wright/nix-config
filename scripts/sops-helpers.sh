#!/usr/bin/env bash
# SOPS helper functions for managing sops.yaml configuration
# Usage: source scripts/sops-helpers.sh

set -e

# Source general helpers first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

SOPS_FILE="${FLAKE_ROOT}/sops.yaml"

# Updates the sops.yaml file with a new host or user age key.
# Usage: sops_update_age_key <field> <keyname> <key>
#   field: "hosts" or "users"
#   keyname: name for the anchor (e.g., hostname or username)
#   key: the age public key
function sops_update_age_key() {
    local field="$1"
    local keyname="$2"
    local key="$3"

    if [ ! "$field" == "hosts" ] && [ ! "$field" == "users" ]; then
        red "Invalid field passed to sops_update_age_key. Must be either 'hosts' or 'users'."
        exit 1
    fi

    # Check if key already exists (using Go yq syntax)
    if nix_develop yq-go eval ".keys[] | select(anchor == \"$keyname\")" "$SOPS_FILE" >/dev/null 2>&1; then
        green "Updating existing ${keyname} key"
        nix_develop yq-go eval -i "(.keys[] | select(anchor == \"$keyname\")) = \"$key\"" "$SOPS_FILE"
    else
        green "Adding new ${keyname} key"
        nix_develop yq-go eval -i ".keys += [\"$key\"] | .keys[-1] anchor = \"$keyname\"" "$SOPS_FILE"
    fi
}

# Adds a host-specific creation rule to sops.yaml
# Usage: sops_add_host_creation_rule <hostname>
function sops_add_host_creation_rule() {
    local hostname="$1"
    local h="\"$hostname\""  # quoted hostname for yaml
    local me="\"me\""        # quoted me for yaml

    # Check if a specific rule for this host already exists (using Go yq syntax)
    if nix_develop yq-go eval ".creation_rules[] | select(.path_regex == \"^hosts/$hostname/secrets\\.yaml$\")" "$SOPS_FILE" >/dev/null 2>&1; then
        blue "Creation rule for $hostname already exists"
        return 0
    fi

    green "Adding new host file creation rule for $hostname"
    # Add specific rule for this host (using Go yq syntax)
    nix_develop yq-go eval -i ".creation_rules += [{\"path_regex\": \"^hosts/$hostname/secrets\\.yaml$\", \"key_groups\": [{\"age\": [\"*me\", \"*$hostname\"]}]}]" "$SOPS_FILE"
}

# Adds a host age key to sops.yaml and creates the creation rule
# Usage: sops_add_host_key <hostname> <age_key>
function sops_add_host_key() {
    local hostname="$1"
    local age_key="$2"

    if [ -z "$hostname" ] || [ -z "$age_key" ]; then
        red "sops_add_host_key requires hostname and age_key arguments"
        exit 1
    fi

    if [[ ! "$age_key" =~ ^age1 ]]; then
        red "Invalid age key format: $age_key"
        exit 1
    fi

    # Check if yq-go is available
    if ! nix_develop yq-go --version >/dev/null 2>&1; then
        yellow "yq-go not available via nix develop. Cannot update sops.yaml automatically."
        yellow "Please manually add the following to sops.yaml:"
        echo "  - &$hostname $age_key"
        echo "And add a creation rule:"
        echo "  - path_regex: ^hosts/$hostname/secrets\\.yaml$"
        echo "    key_groups:"
        echo "    - age:"
        echo "      - *me"
        echo "      - *$hostname"
        return 1
    fi

    # Add the key to the keys section
    sops_update_age_key "hosts" "$hostname" "$age_key"
    
    # Add the creation rule
    sops_add_host_creation_rule "$hostname"
    
    green "Added host age key to sops.yaml"
    return 0
}

