{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types optionalString;
  cfg = config.den.aspects.phoenix;

  # Detect if we're on Darwin or NixOS
  isDarwin = pkgs.stdenv.isDarwin;
  isNixOS = !isDarwin;

  # Helper function to create scripts with proper runtime dependencies
  createScript =
    name: script:
    pkgs.writeShellApplication {
      name = name;
      runtimeInputs = with pkgs; [
        git
        nix
      ] ++ lib.optionals isNixOS [ nh ]
        ++ lib.optionals isDarwin [ darwin-rebuild ]
        ++ cfg.extraRuntimeInputs;
      text = script;
    };

  # Get the appropriate rebuild command based on platform
  systemRebuildCmd = if isDarwin then "darwin-rebuild switch --flake" else "nh os switch";
  homeRebuildCmd = if isDarwin then "nix run nixpkgs#home-manager -- switch --flake" else "nh home switch";

  # Individual script functions
  syncScript = createScript "phoenix-sync" ''
    #!/bin/bash
    echo "🔄 Syncing system and user configurations..."

    # Get current hostname and username
    HOSTNAME=$(hostname ${optionalString isDarwin "-s"})
    USERNAME=$(whoami)

    # Sync system
    echo "📦 Updating system configuration..."
    ${systemRebuildCmd} ${cfg.dotfilesDir}#${if isDarwin then "darwinConfigurations" else "nixosConfigurations"}."$HOSTNAME"

    # Sync user
    echo "🏠 Updating user configuration..."
    ${homeRebuildCmd} ${cfg.dotfilesDir}#homeConfigurations."$USERNAME@$HOSTNAME"${optionalString (!isDarwin) ".activationPackage -b backup"}

    # Run post-sync hooks
    phoenix posthook
  '';

  syncSystemScript = createScript "phoenix-sync-system" ''
    #!/bin/bash
    echo "📦 Updating system configuration..."

    # Get current hostname
    HOSTNAME=$(hostname ${optionalString isDarwin "-s"})

    ${systemRebuildCmd} ${cfg.dotfilesDir}#${if isDarwin then "darwinConfigurations" else "nixosConfigurations"}."$HOSTNAME"
    echo "✅ System sync complete!"
  '';

  syncUserScript = createScript "phoenix-sync-user" ''
    #!/bin/bash
    echo "🏠 Updating user configuration..."

    # Get current hostname and username
    HOSTNAME=$(hostname ${optionalString isDarwin "-s"})
    USERNAME=$(whoami)

    ${homeRebuildCmd} ${cfg.dotfilesDir}#homeConfigurations."$USERNAME@$HOSTNAME"${optionalString (!isDarwin) ".activationPackage -b backup"}
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
    HOSTNAME=$(hostname ${optionalString isDarwin "-s"})
    USERNAME=$(whoami)

    ${systemRebuildCmd} ${cfg.dotfilesDir}#${if isDarwin then "darwinConfigurations" else "nixosConfigurations"}."$HOSTNAME"
    ${homeRebuildCmd} ${cfg.dotfilesDir}#homeConfigurations."$USERNAME@$HOSTNAME"${optionalString (!isDarwin) ".activationPackage -b backup"}
    echo "✅ System upgraded!"
  '';

  gcScript = createScript "phoenix-gc" ''
    #!/bin/bash
    echo "🧹 Running garbage collection..."

    if [ "$1" = "full" ]; then
      echo "🗑️ Full garbage collection..."
      ${if isDarwin then
        "nix-collect-garbage -d"
      else
        "nh clean --keep 0"}
    elif [ "$1" ]; then
      echo "🗑️ Garbage collection older than $1..."
      ${if isDarwin then
        "nix-collect-garbage --delete-older-than \"$1\""
      else
        "nh clean --keep-since \"$1\""}
    else
      echo "🗑️ Garbage collection older than ${cfg.defaultGcAge}..."
      ${if isDarwin then
        "nix-collect-garbage --delete-older-than ${cfg.defaultGcAge}"
      else
        "nh clean --keep-since ${cfg.defaultGcAge}"}
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
    runtimeInputs = with pkgs; [
      git
      nix
    ] ++ lib.optionals isNixOS [ nh ]
      ++ lib.optionals isDarwin [ darwin-rebuild ]
      ++ cfg.extraRuntimeInputs;
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
          echo "Platform: ${if isDarwin then "macOS (Darwin)" else "NixOS"}"
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

  # Default post-hook scripts for different platforms
  defaultNixOSPostHookScript = ''
    # Hyprland-specific reloads
    if pgrep Hyprland &> /dev/null; then
      echo "🔄 Reloading Hyprland..."
      hyprctl reload &> /dev/null || true
    fi

    # Restart waybar if running
    if pgrep .waybar-wrapped &> /dev/null; then
      echo "📊 Restarting waybar..."
      killall .waybar-wrapped &> /dev/null || true
      waybar &> /dev/null & disown
    fi

    # Restart fnott if running
    if pgrep fnott &> /dev/null; then
      echo "🔔 Restarting fnott..."
      killall fnott &> /dev/null || true
      fnott &> /dev/null & disown
    fi

    # Stop hyprpaper if running (we use mpvpaper instead)
    if pgrep hyprpaper &> /dev/null; then
      echo "🖼️ Stopping hyprpaper (using mpvpaper instead)..."
      killall hyprpaper &> /dev/null || true
    fi

    # Restart dunst if running (for notifications)
    if pgrep .dunst-wrapped &> /dev/null; then
      echo "📢 Restarting dunst..."
      killall .dunst-wrapped &> /dev/null || true
      dunst &> /dev/null & disown
    fi
  '';

  defaultDarwinPostHookScript = ''
    # macOS-specific post-hooks
    echo "🍎 Running macOS-specific hooks..."

    # Restart yabai if running
    if pgrep yabai &> /dev/null; then
      echo "🪟 Restarting yabai..."
      yabai --restart-service || true
    fi

    # Restart skhd if running
    if pgrep skhd &> /dev/null; then
      echo "⌨️ Restarting skhd..."
      skhd --restart-service || true
    fi

    # Restart sketchybar if running
    if pgrep sketchybar &> /dev/null; then
      echo "📊 Restarting sketchybar..."
      sketchybar --reload || true
    fi

    # Restart borders if running
    if pgrep borders &> /dev/null; then
      echo "🖼️ Restarting borders..."
      killall borders &> /dev/null || true
      borders &> /dev/null & disown
    fi
  '';

  defaultPostHookScript = if isDarwin then defaultDarwinPostHookScript else defaultNixOSPostHookScript;
in
{
  options.den.aspects.phoenix = {
    enable = mkEnableOption "Phoenix system management tool";

    dotfilesDir = mkOption {
      type = types.str;
      default = if isDarwin then "/Users/$(whoami)/nix-config" else "/home/$(whoami)/nix-config";
      description = "Path to the dotfiles directory";
    };

    defaultGcAge = mkOption {
      type = types.str;
      default = "30d";
      description = "Default age for garbage collection";
    };

    postHookScript = mkOption {
      type = types.str;
      default = defaultPostHookScript;
      description = "Custom script to run during post-hooks";
    };

    extraRuntimeInputs = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to include in phoenix script runtime";
    };
  };

  config = mkIf cfg.enable {
    # Install phoenix on both platforms
    environment.systemPackages = lib.optionals isNixOS [
      phoenixScript
    ];

    # For Darwin, we need to use homebrew or add to system packages differently
    # This will be handled by nix-darwin
    system = lib.optionalAttrs isDarwin {
      packages = [
        phoenixScript
      ];
    };
  };
}
