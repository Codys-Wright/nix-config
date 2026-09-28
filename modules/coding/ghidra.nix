# Ghidra reverse engineering suite with ghidra-cli
{ fleet, inputs, ... }:
{
  flake-file.inputs.ghidra-cli.url = "github:Codys-Wright/ghidra-cli/fix/ghidra-12-compat";

  fleet.coding._.ghidra = {
    description = "ghidra-cli — command-line interface to Ghidra (Ghidra itself: tools/reverse-engineering)";

    # ghidra + ghidra-cli pull in linux-only deps (ghidra-cli references the
    # removed darwin.apple_sdk_11_0 stub); skip the whole aspect on darwin.
    homeManager =
      { pkgs, lib, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      lib.mkIf pkgs.stdenv.isLinux {
        # Ghidra itself (with kaiju/ret-sync/findcrypt) comes from
        # <fleet.coding._.tools/reverse-engineering>; a plain ghidra here
        # shadowed it on PATH (home profile precedes the system one).
        home.packages = [ inputs.ghidra-cli.packages.${system}.ghidra-cli ];
      };
  };
}
