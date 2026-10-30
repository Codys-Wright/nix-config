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
      { pkgs, ... }:
      let
        # Fixed settings (the old per-host options were never set).
        cfg = {
          dotfilesDir = "$HOME/.flake";
          defaultGcAge = "30d";
          postHookScript = defaultPostHookScript;
          extraRuntimeInputs = [ ];
        };

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

        # niri and Loft reload their own config; nothing to poke.
        defaultPostHookScript = "";
      in
      {
        environment.systemPackages = [
          scripts.phoenixScript
        ];
      };

    darwin =
      { pkgs, ... }:
      let
        # Fixed settings (the old per-host options were never set).
        cfg = {
          dotfilesDir = "$HOME/.flake";
          defaultGcAge = "30d";
          postHookScript = defaultPostHookScript;
          extraRuntimeInputs = [ ];
        };

        scripts = mkScripts {
          inherit pkgs cfg;
          baseRuntimeInputs = with pkgs; [
            git
            nix
            # darwin-rebuild: nix-darwin puts it on PATH (not a nixpkgs attr).
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
        environment.systemPackages = [
          scripts.phoenixScript
        ];
      };
  };
}
