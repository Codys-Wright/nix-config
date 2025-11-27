# Switch to a specific host configuration
switch host:
    nh darwin switch 'path:.#' -H {{host}}

# Build a host configuration without switching
build host:
    nh darwin build 'path:.#' -H {{host}}

# Show available hosts
hosts:
    nix eval ".#darwinConfigurations" --apply "builtins.attrNames" --json

# Show available home configurations
homes:
    nix eval ".#homeConfigurations" --apply "builtins.attrNames" --json

# Format code
fmt:
    nix run ".#fmt"

# Regenerate flake.nix from flake-file
write-flake:
    nix run ".#write-flake"

# Update flake.lock
update:
    nix flake update

# Show flake structure
show:
    nix flake show

# Enter development shell
dev:
    nix develop
