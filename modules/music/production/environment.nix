# Music production environment - plugin paths and audio configuration
# Sets up environment variables for DAWs to find plugins
{
  FTS,
  inputs,
  ...
}:
{
  flake-file.inputs.musnix.url = "github:musnix/musnix";

  FTS.music._.production._.environment = {
    description = ''
      Music production environment configuration.
      Sets up plugin paths (LV2, CLAP, VST, VST3, LADSPA, DSSI) for DAWs.
      Includes musnix for base audio optimizations and plugin path setup.
    '';

    nixos = { pkgs, config, ... }: {
      imports = [inputs.musnix.nixosModules.musnix];

      # Enable musnix for base plugin paths (VST, VST3, LV2, LADSPA, DSSI, LXVST)
      # CLAP_PATH is already set by nixpkgs shells-environment.nix
      musnix.enable = true;

      # Ensure plugin directories exist in profile
      environment.pathsToLink = [
        "/lib/clap"
        "/lib/lv2"
        "/lib/vst"
        "/lib/vst3"
        "/lib/ladspa"
        "/lib/dssi"
      ];
    };

    homeManager = { pkgs, config, ... }: {
      # Create user plugin directories
      home.file.".clap/.keep".text = "";
      home.file.".lv2/.keep".text = "";
      home.file.".vst/.keep".text = "";
      home.file.".vst3/.keep".text = "";
      home.file.".ladspa/.keep".text = "";
      home.file.".dssi/.keep".text = "";
    };
  };
}
