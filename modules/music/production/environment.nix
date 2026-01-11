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
      # Create plugin directories with nixos/ subdirectory for Nix-managed plugins
      # This keeps the parent directories writable for user-installed plugins
      home.file.".clap/nixos".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/clap";
      home.file.".lv2/nixos".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/lv2";
      home.file.".vst/nixos".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst";
      home.file.".vst3/nixos".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst3";
      home.file.".ladspa/nixos".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/ladspa";
      home.file.".dssi/nixos".source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/dssi";
    };
  };
}
