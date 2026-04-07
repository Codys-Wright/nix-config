# systemd-boot bootloader aspect
# Can be combined with lanzaboote for secure boot.
#
# Usage:
#   <fleet/systemd-boot>
#   (fleet.systemd-boot { secureBoot = true; })
{
  lib,
  fleet,
  inputs,
  den,
  ...
}:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v1.0.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.systemd-boot = {
    description = "systemd-boot bootloader, optionally with lanzaboote secure boot";

    __functor =
      _self:
      {
        secureBoot ? false,
        configurationLimit ? 15,
      }:
      { class, aspect-chain }:
      {
        nixos =
          { lib, pkgs, ... }:
          lib.mkMerge [
            {
              boot.loader.systemd-boot.enable = lib.mkForce (!secureBoot);
              boot.loader.systemd-boot.configurationLimit = configurationLimit;
              boot.loader.efi.canTouchEfiVariables = true;
            }

            (lib.mkIf secureBoot {
              imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

              boot.loader.systemd-boot.enable = lib.mkForce false;
              boot.lanzaboote = {
                enable = true;
                pkiBundle = "/var/lib/sbctl";
              };

              environment.systemPackages = [ pkgs.sbctl ];
            })
          ];
      };
  };
}
