# studio-linux — niri + its own Quickshell shell (Liquid Glass, runtime
# themes) and a Spotlight launcher: github:Codys-Wright/studio-linux.
#
# Opt-in per host; Noctalia stays the default:
#   den.hosts.x86_64-linux.<host>.settings.desktop.shell = "studio";
#
# Users then get studio's home-manager module (shell + launcher services,
# the `studio` CLI). The niri aspect switches the shell it starts and
# includes studio's niri fragment (keybinds + the active theme).
{ inputs, lib, ... }:
{
  flake-file.inputs.studio-linux = {
    url = lib.mkDefault "github:Codys-Wright/studio-linux";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.desktop._.studio = {
    description = "studio-linux desktop shell + launcher (when settings.desktop.shell = \"studio\")";

    provides.to-users.includes = [
      (
        { host, ... }:
        {
          homeManager = {
            imports = [ inputs.studio-linux.homeManagerModules.default ];
            programs.studio-linux.enable = host.settings.desktop.shell == "studio";
          };
        }
      )
    ];
  };
}
