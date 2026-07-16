# Shared script-building logic for the phoenix aspect.
# Plain function file (underscore-prefixed dir => ignored by import-tree).
# Called once per platform; every platform-varying token is a parameter so the
# resulting writeShellApplication texts stay byte-identical with the originals.
{
  pkgs,
  cfg,
  baseRuntimeInputs, # platform base packages (nh vs darwin-rebuild)
  hostnameCmd, # "hostname" (NixOS) vs "hostname -s" (Darwin)
  systemRebuildCmd, # "nh os switch" vs "darwin-rebuild switch --flake"
  homeRebuildCmd, # "nh home switch" vs "nix run nixpkgs#home-manager -- switch --flake"
  systemConfigAttr, # "nixosConfigurations" vs "darwinConfigurations"
  homeSwitchSuffix, # ".activationPackage -b backup" (NixOS) vs "" (Darwin)
  gcFullCmd, # "nh clean --keep 0" vs "nix-collect-garbage -d"
  gcSinceCmd, # "nh clean --keep-since" vs "nix-collect-garbage --delete-older-than"
  platformName, # "NixOS" vs "macOS (Darwin)"
}:
let
  # Helper function to create scripts with proper runtime dependencies
  createScript =
    name: script:
    pkgs.writeShellApplication {
      name = name;
      runtimeInputs = baseRuntimeInputs ++ cfg.extraRuntimeInputs;
      text = script;
    };

  # Individual script functions
  syncScript = createScript "phoenix-sync" ''
    #!/bin/bash
    echo "🔄 Syncing system and user configurations..."

    # Get current hostname and username
    HOSTNAME=$(${hostnameCmd})
    USERNAME=$(whoami)

    # Sync system
    echo "📦 Updating system configuration..."
    ${systemRebuildCmd} ${cfg.dotfilesDir}#${systemConfigAttr}."$HOSTNAME"

    # Sync user
    echo "🏠 Updating user configuration..."
    ${homeRebuildCmd} ${cfg.dotfilesDir}#homeConfigurations."$USERNAME@$HOSTNAME"${homeSwitchSuffix}

    # Run post-sync hooks
    phoenix posthook
  '';

  syncSystemScript = createScript "phoenix-sync-system" ''
    #!/bin/bash
    echo "📦 Updating system configuration..."

    # Get current hostname
    HOSTNAME=$(${hostnameCmd})

    ${systemRebuildCmd} ${cfg.dotfilesDir}#${systemConfigAttr}."$HOSTNAME"
    echo "✅ System sync complete!"
  '';

  syncUserScript = createScript "phoenix-sync-user" ''
    #!/bin/bash
    echo "🏠 Updating user configuration..."

    # Get current hostname and username
    HOSTNAME=$(${hostnameCmd})
    USERNAME=$(whoami)

    ${homeRebuildCmd} ${cfg.dotfilesDir}#homeConfigurations."$USERNAME@$HOSTNAME"${homeSwitchSuffix}
    echo "✅ User sync complete!"
  '';

  updateScript = createScript "phoenix-update" ''
    #!/bin/bash
    echo "🔄 Updating flake inputs..."
    cd ${cfg.dotfilesDir}
    nix flake update
    echo "✅ Flake inputs updated!"
  '';

  upgradeScript = createScript "phoenix-upgrade" ''
    #!/bin/bash
    echo "⬆️ Upgrading system..."
    cd ${cfg.dotfilesDir}
    nix flake update

    # Get current hostname and username
    HOSTNAME=$(${hostnameCmd})
    USERNAME=$(whoami)

    ${systemRebuildCmd} ${cfg.dotfilesDir}#${systemConfigAttr}."$HOSTNAME"
    ${homeRebuildCmd} ${cfg.dotfilesDir}#homeConfigurations."$USERNAME@$HOSTNAME"${homeSwitchSuffix}
    echo "✅ System upgraded!"
  '';

  gcScript = createScript "phoenix-gc" ''
    #!/bin/bash
    echo "🧹 Running garbage collection..."

    if [ "$1" = "full" ]; then
      echo "🗑️ Full garbage collection..."
      ${gcFullCmd}
    elif [ "$1" ]; then
      echo "🗑️ Garbage collection older than $1..."
      ${gcSinceCmd} "$1"
    else
      echo "🗑️ Garbage collection older than ${cfg.defaultGcAge}..."
      ${gcSinceCmd} ${cfg.defaultGcAge}
    fi

    echo "✅ Garbage collection complete!"
  '';

  posthookScript = createScript "phoenix-posthook" ''
    #!/bin/bash
    echo "🎨 Running post-sync hooks..."

    ${cfg.postHookScript}

    echo "✅ Post-sync hooks complete!"
  '';

  # Main phoenix script
  phoenixScript = pkgs.writeShellApplication {
    name = "phoenix";
    runtimeInputs = baseRuntimeInputs ++ cfg.extraRuntimeInputs;
    text = ''
      #!/bin/bash

      case "$1" in
        "sync")
          if [ "$#" = 1 ]; then
            ${syncScript}/bin/phoenix-sync
          elif [ "$2" = "user" ]; then
            ${syncUserScript}/bin/phoenix-sync-user
          elif [ "$2" = "system" ]; then
            ${syncSystemScript}/bin/phoenix-sync-system
          else
            echo "❌ Please pass 'system' or 'user' if supplying a second argument"
            exit 1
          fi
          ;;
        "update")
          ${updateScript}/bin/phoenix-update
          ;;
        "upgrade")
          ${upgradeScript}/bin/phoenix-upgrade
          ;;
        "gc")
          ${gcScript}/bin/phoenix-gc "$2"
          ;;
        "posthook")
          ${posthookScript}/bin/phoenix-posthook
          ;;
        *)
          echo "🚀 Phoenix - Cross-Platform Nix Configuration Manager"
          echo "Platform: ${platformName}"
          echo ""
          echo "Usage: phoenix <command> [options]"
          echo ""
          echo "Commands:"
          echo "  sync [system|user]  Sync system and/or user configuration"
          echo "  update              Update flake inputs"
          echo "  upgrade             Update and apply all changes"
          echo "  gc [time|full]      Run garbage collection"
          echo "  posthook            Run post-sync hooks to reload services"
          echo ""
          echo "Examples:"
          echo "  phoenix sync        # Sync both system and user"
          echo "  phoenix sync system # Sync only system"
          echo "  phoenix sync user   # Sync only user"
          echo "  phoenix gc 7d       # Remove generations older than 7 days"
          echo "  phoenix gc full     # Remove all old generations"
          ;;
      esac
    '';
  };
in
{
  inherit
    syncScript
    syncSystemScript
    syncUserScript
    updateScript
    upgradeScript
    gcScript
    posthookScript
    phoenixScript
    ;
}
