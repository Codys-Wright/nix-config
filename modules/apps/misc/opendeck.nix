{
  fleet.apps._.misc._.opendeck = {
    description = "OpenDeck - Stream Deck controller software";

    nixos =
      { pkgs, ... }:
      let
        opendeck = pkgs.callPackage ../../../packages/opendeck/opendeck.nix { };
      in
      {
        environment.systemPackages = [ opendeck ];
        services.udev.packages = [ opendeck ];
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          (pkgs.callPackage ../../../packages/opendeck/opendeck.nix { })
        ];
      };
  };
}
