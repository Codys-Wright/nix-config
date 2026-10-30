{
  inputs,
  lib,
  fleet,
  ...
}:
{
  fleet.nix._.nix-registry = {
    description = "Nix registry configuration from flake inputs";

    homeManager =
      { pkgs, ... }:
      {
        nix.registry = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
          lib.mapAttrs (_name: v: { flake = v; }) (
            # nix-secrets is private: pinning it would copy its source into
            # every host's world-readable /nix/store.
            lib.filterAttrs (name: value: value ? outputs && name != "nix-secrets") inputs
          )
        );
      };
  };
}
