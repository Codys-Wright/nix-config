# Loft — niri + its own Quickshell shell (Liquid Glass, runtime
# themes) and a Spotlight launcher: github:Codys-Wright/loft.
#
# The desktop shell on every host with fleet.desktop. A user opts out with
#   den.aspects."<user>@<host>".homeManager.programs.loft.enable = false;
#
# Users get Loft's home-manager module (shell + launcher services,
# idle locking, the `loft` CLI). The niri aspect switches the shell it
# starts and includes Loft's niri fragment (keybinds + the active theme).
# The host's login screen becomes Loft's SDDM theme (same design as the
# lock screen).
{ inputs, lib, ... }:
{
  flake-file.inputs.loft = {
    url = lib.mkDefault "github:Codys-Wright/loft";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.desktop._.loft = {
    description = "Loft desktop shell + launcher";

    # Loft's NixOS module: the login screen (SDDM theme `loft`) that follows
    # each user's lock screen design (`loft greeter sync`).
    nixos =
      { lib, ... }:
      {
        imports = [ inputs.loft.nixosModules.default ];
        programs.loft.greeter.enable = lib.mkDefault true;
      };

    provides.to-users.includes = [
      {
        homeManager = { lib, ... }: {
          imports = [ inputs.loft.homeManagerModules.default ];
          programs.loft.enable = lib.mkDefault true;
          # Loft's keyboard layer: the macOS-style remaps come from Loft
          # (`loft keys show`), xremap runs them (loft-keys.service), agents
          # change them at runtime (`loft keys app …`). The fleet's niri
          # input (lv3:ralt_switch + lv3:lwin_switch) makes Left Super a mod
          # key too, so the groups that rely on that are on here.
          programs.loft.keyboard = {
            enable = lib.mkDefault true;
            groups = lib.mapAttrs (_: lib.mkDefault) {
              right-ctrl-mod = true;
              mac-screenshots = true;
              symbols = true;
              terminal-cmd-swallow = true;
            };
          };
        };
      }
    ];
  };
}
