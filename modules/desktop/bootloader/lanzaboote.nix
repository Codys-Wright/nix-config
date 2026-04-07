# Lanzaboote secure boot bootloader aspect
# Requires one-time key setup: sudo sbctl create-keys
# Then enroll keys in BIOS after first rebuild.
#
# Usage:
#   <fleet/lanzaboote>
#   (fleet.lanzaboote { configurationLimit = 20; })
{
  fleet,
  inputs,
  ...
}:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v1.0.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.lanzaboote = {
    description = "Lanzaboote UEFI secure boot bootloader";

    __functor =
      _self:
      {
        configurationLimit ? 15,
        pkiBundle ? "/var/lib/sbctl",
      }:
      { class, aspect-chain }:
      {
        nixos =
          { lib, pkgs, ... }:
          {
            imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.loader.efi.canTouchEfiVariables = true;

            boot.lanzaboote = {
              enable = true;
              inherit pkiBundle;
              inherit configurationLimit;
            };

            environment.systemPackages = [ pkgs.sbctl ];
          };
      };
  };
}
