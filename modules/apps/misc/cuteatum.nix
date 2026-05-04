{
  fleet.apps._.misc._.cuteatum = {
    description = "CuteAtum - Linux ATEM switcher controller";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          (pkgs.callPackage ../../../packages/cuteatum/cuteatum.nix { })
        ];
      };
  };
}
