# Ghidra reverse engineering suite with ghidra-cli
{ fleet, inputs, ... }:
{
  flake-file.inputs.ghidra-cli.url = "github:Codys-Wright/ghidra-cli/fix/ghidra-12-compat";

  fleet.coding._.ghidra = {
    description = "Ghidra reverse engineering suite with CLI interface";

    homeManager =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        home.packages = [
          pkgs.ghidra
          inputs.ghidra-cli.packages.${system}.ghidra-cli
        ];
      };
  };
}
