# studio-linux — niri + its own Quickshell shell (Liquid Glass, runtime
# themes) and a Spotlight launcher: github:Codys-Wright/studio-linux.
#
# Opt-in per host; Noctalia stays the default:
#   den.hosts.x86_64-linux.<host>.settings.desktop.shell = "studio";
# or per user on one host (login screen unchanged):
#   den.aspects."<user>@<host>".homeManager.programs.studio-linux.enable = true;
#
# Users then get studio's home-manager module (shell + launcher services,
# idle locking, the `studio` CLI). The niri aspect switches the shell it
# starts and includes studio's niri fragment (keybinds + the active theme).
# The host's login screen becomes studio's SDDM theme (same design as the
# lock screen).
{ inputs, lib, ... }:
{
  flake-file.inputs.studio-linux = {
    url = lib.mkDefault "github:Codys-Wright/studio-linux";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.desktop._.studio = {
    description = "studio-linux desktop shell + launcher (when settings.desktop.shell = \"studio\")";

    nixos =
      {
        host,
        lib,
        pkgs,
        ...
      }:
      lib.mkIf (host.settings.desktop.shell == "studio") {
        environment.systemPackages = [
          inputs.studio-linux.packages.${pkgs.stdenv.hostPlatform.system}.studio-sddm-theme
        ];
        services.displayManager.sddm = {
          theme = "studio";
          # Lets the greeter read /var/lib/studio-linux/greeter/theme.json.
          settings.General.GreeterEnvironment = "QML_XHR_ALLOW_FILE_READ=1";
        };
      };

    provides.to-users.includes = [
      (
        { host, ... }:
        {
          homeManager = { lib, ... }: {
            imports = [ inputs.studio-linux.homeManagerModules.default ];
            # A user can opt in on their own (den.aspects."<user>@<host>").
            programs.studio-linux.enable = lib.mkDefault (host.settings.desktop.shell == "studio");
          };
        }
      )
    ];
  };
}
