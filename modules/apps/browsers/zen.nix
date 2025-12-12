# Zen Browser aspect
{
  inputs,
  lib,
  FTS,
  ...
}:
{
  flake-file.inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  FTS.apps._.browsers._.zen = {
    description = "Zen Browser - Beautiful Firefox-based browser with privacy features";

    homeManager = { config, pkgs, lib, ... }: {
      imports = [
        inputs.zen-browser.homeModules.twilight
      ];

      programs.zen-browser.policies = {
        DisableAppUpdate = true;
        DisableTelemetry = true;
        # find more options here: https://mozilla.github.io/policy-templates/
      };
    };
  };
}

