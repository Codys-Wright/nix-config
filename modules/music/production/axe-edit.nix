# Axe-Edit III - Editor/librarian for Fractal Audio Systems devices
# Runs via Wine (mkWindowsApp from erosanix) with cursor fix
{
  inputs,
  fleet,
  ...
}:
{
  # Add erosanix flake input for mkWindowsApp
  flake-file.inputs.erosanix.url = "github:emmanuelrosa/erosanix";

  fleet.music._.production._.axeEdit = {
    description = "Fractal Audio Axe-Edit III editor/librarian via Wine";

    homeManager =
      { pkgs, ... }:
      let
        erosanix = inputs.erosanix.packages.${pkgs.system};
        erosanixLib = inputs.erosanix.lib.${pkgs.system};
      in
      {
        home.packages = [
          (pkgs.callPackage ../../../packages/axe-edit-iii/axe-edit-iii.nix {
            inherit (erosanixLib) mkWindowsApp makeDesktopIcon copyDesktopIcons;
            wine = pkgs.wineWow64Packages.full;
          })
        ];
      };
  };
}
