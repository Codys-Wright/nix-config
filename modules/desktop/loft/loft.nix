# Loft — niri + its own Quickshell shell (Liquid Glass, runtime
# themes) and a Spotlight launcher: github:Codys-Wright/loft.
#
# Opt-in per host; Noctalia stays the default:
#   den.hosts.x86_64-linux.<host>.settings.desktop.shell = "loft";
# or per user on one host (login screen unchanged):
#   den.aspects."<user>@<host>".homeManager.programs.loft.enable = true;
#
# Users then get Loft's home-manager module (shell + launcher services,
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
    description = "Loft desktop shell + launcher (when settings.desktop.shell = \"loft\")";

    nixos =
      {
        host,
        lib,
        pkgs,
        ...
      }:
      lib.mkIf (host.settings.desktop.shell == "loft") {
        environment.systemPackages = [
          inputs.loft.packages.${pkgs.stdenv.hostPlatform.system}.loft-sddm-theme
        ];
        services.displayManager.sddm = {
          theme = "loft";
          # Lets the greeter read /var/lib/loft/greeter/theme.json.
          settings.General.GreeterEnvironment = "QML_XHR_ALLOW_FILE_READ=1";
        };
      };

    provides.to-users.includes = [
      (
        { host, ... }:
        {
          homeManager = { lib, ... }: {
            imports = [ inputs.loft.homeManagerModules.default ];
            # A user can opt in on their own (den.aspects."<user>@<host>").
            programs.loft.enable = lib.mkDefault (host.settings.desktop.shell == "loft");
          };
        }
      )
    ];
  };
}
