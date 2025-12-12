#!/usr/bin/env bash
# SOPS helper functions for managing sops.yaml configuration
# Usage: source scripts/sops-helpers.sh

set -e

# Source general helpers first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

SOPS_FILE="${FLAKE_ROOT}/sops.yaml"

# Updates the sops.yaml file with a new age key.
# Usage: sops_update_age_key <keyname> <key>
#   keyname: name for the anchor (e.g., hostname or username)
#   key: the age public key
function sops_update_age_key() {
    local keyname="$1"
    local key="$2"

    # Check if key already exists (using Go yq syntax)
    EXISTING=$(nix_develop yq eval ".keys[] | select(anchor == \"$keyname\")" "$SOPS_FILE" 2>/dev/null || true)
    if [ -n "$EXISTING" ]; then
        green "Updating existing ${keyname} key"
        nix_develop yq eval -i "(.keys[] | select(anchor == \"$keyname\")) = \"$key\"" "$SOPS_FILE"
    else
        green "Adding new ${keyname} key"
        nix_develop yq eval -i ".keys += [\"$key\"] | .keys[-1] anchor = \"$keyname\"" "$SOPS_FILE"
    fi
}

# Adds a host-specific creation rule to sops.yaml
# Usage: sops_add_host_creation_rule <hostname>
function sops_add_host_creation_rule() {
    local hostname="$1"
    local h="\"$hostname\""  # quoted hostname for yaml
    local me="\"me\""        # quoted me for yaml

    # Check if a specific rule for this host already exists (using Go yq syntax)
    EXISTING_RULE=$(nix_develop yq eval ".creation_rules[] | select(.path_regex == \"^hosts/$hostname/secrets\\.yaml$\")" "$SOPS_FILE" 2>/dev/null || true)
    if [ -n "$EXISTING_RULE" ]; then
        blue "Creation rule for $hostname already exists"
        return 0
    fi

    green "Adding new host file creation rule for $hostname"
    # Add creation rule with placeholder values, then convert to aliases
    local h="\"$hostname\""
    local m="\"me\""
    local host_selector=".creation_rules[] | select(.path_regex == \"^hosts/$hostname/secrets\\\\.yaml\$\")"
    
    # First add the rule with placeholder string values
    nix_develop yq eval -i ".creation_rules += [{\"path_regex\": \"^hosts/$hostname/secrets\\\\.yaml$\", \"key_groups\": [{\"age\": [$m, $h]}]}]" "$SOPS_FILE"
    
    # Then convert those strings to YAML aliases/anchors using the 'alias' keyword
    nix_develop yq eval -i "($host_selector).key_groups[].age[0] alias = $m" "$SOPS_FILE"
    nix_develop yq eval -i "($host_selector).key_groups[].age[1] alias = $h" "$SOPS_FILE"
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

    # Check if yq is available (from yq-go package)
    if ! nix_develop yq --version >/dev/null 2>&1; then
        yellow "yq (from yq-go) not available. Cannot update sops.yaml automatically."
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
    sops_update_age_key "$hostname" "$age_key"
    
    # Add the creation rule
    sops_add_host_creation_rule "$hostname"
    
    green "Added host age key to sops.yaml"
    return 0
}

