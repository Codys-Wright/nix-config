# Music production environment - plugin paths and audio configuration
# Sets up environment variables for DAWs to find plugins
{
  fleet,
  inputs,
  lib,
  ...
}:
let
  audioProduction = import ../../../lib/audio/production/common.nix { inherit lib; };
in
{
  flake-file.inputs.musnix.url = "github:musnix/musnix";

  fleet.music._.production._.environment = {
    description = ''
      Music production environment configuration.
      Sets up plugin paths (LV2, CLAP, VST, VST3, LADSPA, DSSI) for DAWs.
      Includes musnix for base audio optimizations and plugin path setup.
    '';

    nixos =
      { pkgs, config, ... }:
      {
        imports = [ inputs.musnix.nixosModules.musnix ];

        # Enable musnix for base plugin paths (VST, VST3, LV2, LADSPA, DSSI, LXVST)
        # CLAP_PATH is already set by nixpkgs shells-environment.nix
        musnix.enable = true;

        environment.systemPackages = audioProduction.defaultProductionPackages pkgs;

        # Ensure plugin directories exist in profile
        environment.pathsToLink = map (dir: "/lib/${dir}") audioProduction.defaultPluginDirs;
      };

    homeManager = { config, ... }: audioProduction.mkHomePluginLinks { inherit config; };
  };
}
