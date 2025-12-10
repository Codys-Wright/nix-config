#!/usr/bin/env bash

# Check if sops-nix is running and activated correctly
# Based on emergent-config's check-sops.sh

set -euo pipefail

os=$(uname -s)

if [ "$os" == "Darwin" ]; then
	# macOS: Check launchd
	sops_running=$(launchctl list | rg sops || true)
	if [[ -z $sops_running ]]; then
		echo "ERROR: sops-nix is not running"
		exit 1
	fi
	echo "✓ sops-nix service is running (macOS)"
else
	# Linux: Check systemd user service for home-manager
	# If the sops-nix service wasn't started at all, we don't need to check if it failed
	sops_running=$(journalctl --user --no-pager --no-hostname --since "10 minutes ago" 2>/dev/null | rg "Starting sops-nix activation" || true)
	if [ -z "$sops_running" ]; then
		echo "⚠ sops-nix service hasn't been started in the last 10 minutes"
		echo "  This might be normal if home-manager hasn't been activated yet"
		exit 0
	fi

	# Check if activation finished successfully
	sops_result=$(journalctl --user --no-pager --no-hostname --since "10 minutes ago" 2>/dev/null |
		tac |
		awk '!flag; /Starting sops-nix activation/{flag = 1};' |
		tac |
		rg sops || true)

	# If we don't have "Finished sops-nix activation." in the logs, then we failed
	if [[ ! $sops_result =~ "Finished sops-nix activation" ]]; then
		echo "ERROR: sops-nix failed to activate"
		echo "ERROR: $sops_result"
		exit 1
	fi
	
	echo "✓ sops-nix activation finished successfully"
fi

# Check if age key exists for home-manager
if [ -f ~/.config/sops/age/keys.txt ]; then
	echo "✓ Age key found at ~/.config/sops/age/keys.txt"
else
	echo "⚠ Age key not found at ~/.config/sops/age/keys.txt"
	echo "  This might be normal if the system hasn't been rebuilt yet"
fi

# Check if secrets directory exists
if [ -d ~/.config/sops-nix/secrets ]; then
	secret_count=$(find ~/.config/sops-nix/secrets -type f 2>/dev/null | wc -l)
	echo "✓ Secrets directory exists with $secret_count secret(s)"
else
	echo "⚠ Secrets directory not found at ~/.config/sops-nix/secrets"
	echo "  This might be normal if no secrets are declared yet"
fi

exit 0

