# Standalone niri package with config embedded via wrapper-modules.
# Run with: nix run .#niri
#
# Uses BirdeeHub/nix-wrapper-modules to evaluate flake.wrapperModules.niri,
# generating a niri binary with the full config baked in.
# Mod key is Super — press Super+D, Super+Space etc. inside the nested window.
{
  inputs,
  self,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        imports = [ self.wrapperModules.niri ];
      };
    };
}
