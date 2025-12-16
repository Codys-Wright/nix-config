{
  inputs,
  lib,
  pkgs,
  FTS,
  ...
}: {
  # npins aspect - Pin management tool for Nix flakes
  FTS.nix._.npins = {
    description = "npins - Pin management tool for Nix flakes";

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.npins];
    };

    darwin = {pkgs, ...}: {
      environment.systemPackages = [pkgs.npins];
    };

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.npins];
    };
  };

  # Note: To use npins sources in other modules (e.g., nvf.nix),
  # import them directly: `import ../../npins/default.nix`
  # This returns a set of all pinned sources that can be used to build plugins.
}
