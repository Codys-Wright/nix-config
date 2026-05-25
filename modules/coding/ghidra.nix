# Ghidra reverse engineering suite with ghidra-cli
{ fleet, inputs, ... }:
{
  flake-file.inputs.ghidra-cli.url = "github:Codys-Wright/ghidra-cli/fix/ghidra-12-compat";

  fleet.coding._.ghidra = {
    description = "Ghidra reverse engineering suite with CLI interface";

    # ghidra + ghidra-cli pull in linux-only deps (ghidra-cli references the
    # removed darwin.apple_sdk_11_0 stub); skip the whole aspect on darwin.
    homeManager =
      { pkgs, lib, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      lib.mkIf pkgs.stdenv.isLinux {
        home.packages = [
          pkgs.ghidra
          inputs.ghidra-cli.packages.${system}.ghidra-cli
        ];
      };
  };
}
