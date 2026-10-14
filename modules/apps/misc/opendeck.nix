{
  fleet.apps._.misc._.opendeck = {
    description = "OpenDeck - Stream Deck controller software";

    provides.to-hosts.nixos =
      { pkgs, ... }:
      let
        opendeck = pkgs.opendeck;
      in
      {
        environment.systemPackages = [ opendeck ];
        services.udev.packages = [ opendeck ];
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.opendeck
        ];
      };
  };
}
