{
  fleet,
  ...
}:
let
  mkScripts = import ./_lib/scripts.nix;
in
{
  fleet.phoenix = {
    description = "Phoenix system management tool for cross-platform Nix configurations";

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        inherit (lib)
          mkIf
          mkEnableOption
          mkOption
          types
          optionalString
          ;
        cfg = config.fleet.phoenix;

        scripts = mkScripts {
          inherit pkgs cfg;
          baseRuntimeInputs = with pkgs; [
            git
            nix
            nh
          ];
          hostnameCmd = "hostname";
          systemRebuildCmd = "nh os switch";
          homeRebuildCmd = "nh home switch";
          systemConfigAttr = "nixosConfigurations";
          homeSwitchSuffix = ".activationPackage -b backup";
          gcFullCmd = "nh clean --keep 0";
          gcSinceCmd = "nh clean --keep-since";
          platformName = "NixOS";
        };

        # Default post-hook scripts for NixOS
        defaultPostHookScript = ''
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
      in
      {
        options.fleet.phoenix = {
          enable = mkEnableOption "Phoenix system management tool";

          dotfilesDir = mkOption {
            type = types.str;
            default = "/home/$(whoami)/nix-config";
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
            default = [ ];
            description = "Additional packages to include in phoenix script runtime";
          };
        };

        config = mkIf cfg.enable {
          environment.systemPackages = [
            scripts.phoenixScript
          ];
        };
      };

    darwin =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        inherit (lib)
          mkIf
          mkEnableOption
          mkOption
          types
          ;
        cfg = config.fleet.phoenix;

        scripts = mkScripts {
          inherit pkgs cfg;
          baseRuntimeInputs = with pkgs; [
            git
            nix
            darwin-rebuild
          ];
          hostnameCmd = "hostname -s";
          systemRebuildCmd = "darwin-rebuild switch --flake";
          homeRebuildCmd = "nix run nixpkgs#home-manager -- switch --flake";
          systemConfigAttr = "darwinConfigurations";
          homeSwitchSuffix = "";
          gcFullCmd = "nix-collect-garbage -d";
          gcSinceCmd = "nix-collect-garbage --delete-older-than";
          platformName = "macOS (Darwin)";
        };

        # Default post-hook scripts for Darwin
        defaultPostHookScript = ''
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
      in
      {
        options.fleet.phoenix = {
          enable = mkEnableOption "Phoenix system management tool";

          dotfilesDir = mkOption {
            type = types.str;
            default = "/Users/$(whoami)/nix-config";
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
            default = [ ];
            description = "Additional packages to include in phoenix script runtime";
          };
        };

        config = mkIf cfg.enable {
          environment.systemPackages = [
            scripts.phoenixScript
          ];
        };
      };
  };
}
