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
    # And the "Loft" login session (Plasma with Loft's shell instead of
    # plasmashell) wherever Plasma is installed.
    nixos =
      { config, lib, ... }:
      {
        imports = [ inputs.loft.nixosModules.default ];
        programs.loft.greeter.enable = lib.mkDefault true;
        programs.loft.plasma.enable = lib.mkDefault config.services.desktopManager.plasma6.enable;
      };

    provides.to-users.includes = [
      {
        homeManager = { config, lib, ... }: {
          imports = [ inputs.loft.homeManagerModules.default ];
          programs.loft.enable = lib.mkDefault true;
          # A Plasma login (the "loft" session) rewrites ~/.gtkrc-2.0 and
          # mimeapps.list; home-manager then refuses to activate once its
          # backup name is taken. Its own versions win instead.
          gtk.gtk2.force = lib.mkDefault true;
          xdg.configFile."mimeapps.list".force = lib.mkIf config.xdg.mimeApps.enable true;
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
