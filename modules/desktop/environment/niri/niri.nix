# Niri - Scrollable-tiling Wayland compositor
# Config is defined in _niri-settings.nix (wrapper-modules format).
# The wrapper evaluates the settings into a store-path config.kdl.
# homeManager symlinks ~/.config/niri/config.kdl → that store path.
{
  FTS,
  inputs,
  pkgs,
  ...
}:
{
  FTS.desktop._.environment._.niri = {
    description = ''
      Niri scrollable-tiling Wayland compositor with Noctalia shell.

      A Wayland compositor where windows are arranged in an infinite
      horizontal scrollable strip of columns.

      Homepage: https://github.com/niri-wm/niri
      NixOS module: github:sodiboo/niri-flake
      Config format: github:BirdeeHub/nix-wrapper-modules (_niri-settings.nix)
    '';

    includes = [
      FTS.desktop._.environment._.niri._.xremap
    ];

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.nixosModules.niri ];

        programs.niri.enable = true;

        # XDG portals for screen sharing, file picker, etc.
        xdg.portal = {
          enable = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
            pkgs.xdg-desktop-portal-gnome
          ];
          config.common.default = [
            "gnome"
            "gtk"
          ];
        };

        security.polkit.enable = true;

        environment.systemPackages = with pkgs; [
          xwayland-satellite # XWayland support for legacy apps
          noctalia-shell # Desktop shell (bar + launcher + notifications)
          ghostty # Alternative terminal (Mod+E)
          wlr-which-key # Which-key popup for keybind hints
          swaybg # Wallpaper setter
          swaylock # Screen locker
          swayidle # Idle management
          wl-clipboard # Clipboard utilities
          grim # Screenshot capture
          slurp # Region selection for screenshots
          swappy # Screenshot annotation editor
        ];
      };

    homeManager =
      { pkgs, ... }:
      let
        # Evaluate the wrapper to get the baked config.kdl in the nix store.
        # This is the single source of truth for the niri config — defined in
        # _niri-settings.nix using wrapper-modules format, not programs.niri.settings.
        wrappedNiri = inputs.wrapper-modules.wrappers.niri.wrap {
          inherit pkgs;
          imports = [ (import ./_niri-settings.nix) ];
        };
      in
      {
        # Symlink config.kdl from the nix store — no niri-flake homeModule needed.
        xdg.configFile."niri/config.kdl".source = "${wrappedNiri}/niri-config.kdl";

        # Noctalia colors — Catppuccin Mocha with blue as primary accent.
        xdg.configFile."noctalia/colors.json".text = builtins.toJSON {
          mPrimary = "#89b4fa"; # blue
          mOnPrimary = "#11111b";
          mSecondary = "#cba6f7"; # mauve
          mOnSecondary = "#11111b";
          mTertiary = "#94e2d5"; # teal
          mOnTertiary = "#11111b";
          mError = "#f38ba8"; # red
          mOnError = "#11111b";
          mSurface = "#1e1e2e"; # base
          mOnSurface = "#cdd6f4"; # text
          mSurfaceVariant = "#313244"; # surface1
          mOnSurfaceVariant = "#a3b4eb";
          mOutline = "#4c4f69";
          mShadow = "#11111b";
          mHover = "#89dceb"; # sky
          mOnHover = "#11111b";
        };
      };
  };
}
