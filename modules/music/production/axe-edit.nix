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
      {
        home.packages = [
          # Built by the fleet-packages overlay (wine + erosanix args live there)
          pkgs.axe-edit-iii
        ];
      };
  };
}
