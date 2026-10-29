# Lanzaboote: systemd-boot with UEFI Secure Boot, signed with the host's own
# sbctl keys (pkiBundle). One-time setup on a new host: `sudo sbctl create-keys`,
# rebuild, then enroll the db key in the firmware.
#
#   <fleet/lanzaboote>
{ fleet, inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote/v1.2.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.lanzaboote = {
    description = "Lanzaboote UEFI Secure Boot bootloader (sbctl keys in /var/lib/sbctl)";

    nixos =
      { lib, pkgs, ... }:
      {
        imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.efi.canTouchEfiVariables = true;

        boot.lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
          configurationLimit = 15;
        };

        environment.systemPackages = [ pkgs.sbctl ];
      };
  };
}
