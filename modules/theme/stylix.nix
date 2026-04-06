# Stylix - System-wide styling using base16
# Automatically styles GTK, Qt, terminals, editors, and more
# NOTE: Only configure in nixos, home-manager integration is automatic via nixos
{ inputs, ... }:
{
  flake-file.inputs = {
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.stylix = {
    description = "Stylix - System-wide theming using base16 color schemes";

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          inputs.stylix.nixosModules.stylix
        ];

        # Use Apple San Francisco fonts if available
        stylix = {
          enable = true;
          autoEnable = false;
          base16Scheme = import ./_assets/stylix/tokyonight/default.nix;
          image = null;
          polarity = "dark";

          cursor = {
            name = "MacTahoe-dark-cursors";
            package = pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix { };
            size = 24;
          };

          icons = {
            enable = true;
            dark = "MacTahoe";
            light = "MacTahoe";
            package = pkgs.callPackage ../../packages/mactahoe/icon-theme.nix { };
          };

          fonts = {
            serif = {
              package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
              name = "SFProDisplay Nerd Font";
            };
            sansSerif = {
              package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
              name = "SFProDisplay Nerd Font";
            };
            monospace = {
              package = pkgs.nerd-fonts.jetbrains-mono;
              name = "JetBrainsMono Nerd Font Mono";
            };
            emoji = {
              package = pkgs.noto-fonts-color-emoji;
              name = "Noto Color Emoji";
            };
          };
        };
        # Qt theming disabled — Stylix sets style=kvantum in qt6ct.conf but
        # doesn't ensure the kvantum plugin is in Qt's plugin path, causing
        # plasmashell to black-screen (module "kvantum" is not installed)
        stylix.targets.qt.enable = false;

        # Install the monospace font system-wide via fontconfig
        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];

        # Stylix HM target config — placed in sharedModules because den's
        # mutual-provider doesn't propagate the homeManager block reliably
        # when autoEnable=false is propagated via Stylix's NixOS-to-HM integration.
        home-manager.sharedModules = [
          {
            # Terminal theming via Stylix (colors + JetBrains Mono font)
            stylix.targets.kitty.enable = true;
            stylix.targets.kitty.fonts.enable = true;
            stylix.targets.ghostty.enable = true;
            stylix.targets.ghostty.fonts.enable = true;

            # KDE theming is handled by the MacTahoe KDE theme aspect (whitesur.nix)
            # Stylix KDE target is disabled because it creates its own look-and-feel
            # that conflicts with the MacTahoe look-and-feel package
            stylix.targets.kde.enable = false;

            # Qt theming disabled — same kvantum/plasmashell issue as NixOS level
            stylix.targets.qt.enable = false;
          }
        ];
      };
  };
}
