# Zen Browser aspect
{ inputs, lib,
  FTS, ... }:
{
  flake-file.inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  FTS.zen-browser = {
    description = "Zen Browser with custom configuration";

    homeManager = { config, pkgs, lib, ... }: {
      imports = [
        inputs.zen-browser.homeModules.twilight
      ];

      programs.zen-browser = {
        enable = true;
        policies = {
          DisableAppUpdate = true;
          DisableTelemetry = true;
          # find more options here: https://mozilla.github.io/policy-templates/
        };
      };
    };
  };
}

