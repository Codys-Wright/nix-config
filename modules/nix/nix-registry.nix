{
  inputs,
  lib,
  FTS,
  ...
}:
{
  FTS.nix._.nix-registry = {
    description = "Nix registry configuration from flake inputs";

    homeManager.nix.registry = lib.mapAttrs (_name: v: { flake = v; }) (
      lib.filterAttrs (_name: value: value ? outputs) inputs
    );
  };
}
