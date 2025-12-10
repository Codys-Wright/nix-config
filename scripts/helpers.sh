#!/usr/bin/env bash
# General helper functions for flake management scripts
# Usage: source scripts/helpers.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

### UX helpers

function red() {
    echo -e "\x1B[31m[!] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[31m[!] $($2) \x1B[0m"
    fi
}

function green() {
    echo -e "\x1B[32m[+] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[32m[+] $($2) \x1B[0m"
    fi
}

function blue() {
    echo -e "\x1B[34m[*] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[34m[*] $($2) \x1B[0m"
    fi
}

function yellow() {
    echo -e "\x1B[33m[*] $1 \x1B[0m"
    if [ -n "${2-}" ]; then
        echo -e "\x1B[33m[*] $($2) \x1B[0m"
    fi
}

# Ask yes or no, with yes being the default
function yes_or_no() {
    echo -en "\x1B[34m[?] $* [y/n] (default: y): \x1B[0m"
    while true; do
        read -rp "" yn
        yn=${yn:-y}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
    done
}

# Ask yes or no, with no being the default
function no_or_yes() {
    echo -en "\x1B[34m[?] $* [y/n] (default: n): \x1B[0m"
    while true; do
        read -rp "" yn
        yn=${yn:-n}
        case $yn in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        esac
    done
}

### File and directory helpers

# Check if a directory exists and is not empty
function dir_exists() {
    [ -d "$1" ] && [ "$(ls -A "$1" 2>/dev/null)" ]
}

# Check if a file exists
function file_exists() {
    [ -f "$1" ]
}

# Create directory if it doesn't exist
function ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        green "Created directory: $1"
    fi
}

### Git helpers

# Check if git tree is dirty
function git_is_dirty() {
    ! git diff --quiet || ! git diff --cached --quiet
}

# Get current git branch
function git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown"
}

### Nix helpers

# Run a command in nix develop shell
function nix_develop() {
    nix develop --command "$@"
}

# Check if a nix package is available
function nix_package_available() {
    nix eval "nixpkgs#$1" >/dev/null 2>&1
}

### Validation helpers

# Validate hostname format
function validate_hostname() {
    local hostname="$1"
    if [ -z "$hostname" ]; then
        red "Hostname cannot be empty"
        return 1
    fi
    
    # Hostname should only contain alphanumeric characters, hyphens, and underscores
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        red "Invalid hostname format: $hostname"
        red "Hostname must contain only alphanumeric characters, hyphens, and underscores"
        return 1
    fi
    
    return 0
}

# Validate IP address format (basic check)
function validate_ip() {
    local ip="$1"
    if [ -z "$ip" ]; then
        red "IP address cannot be empty"
        return 1
    fi
    
    # Basic IPv4 validation
    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        red "Invalid IP address format: $ip"
        return 1
    fi
    
    return 0
}

### Error handling

# Cleanup function for trap
CLEANUP_FUNCTIONS=()

function add_cleanup() {
    CLEANUP_FUNCTIONS+=("$1")
}

function run_cleanup() {
    for func in "${CLEANUP_FUNCTIONS[@]}"; do
        $func || true
    done
}

# Set up trap for cleanup on exit
trap run_cleanup EXIT

