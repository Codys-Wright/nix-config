# MelonLoader Installer aspect
{
  fleet,
  ...
}:
{
  fleet.gaming._.melonloader = {
    description = "MelonLoader installer for Unity game modding";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        home.packages = [
          (pkgs.callPackage ../../packages/melonloader-installer/melonloader-installer.nix { })
        ];
      };
  };
}
