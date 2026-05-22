{ lib }:
let
  defaultPluginDirs = [
    "clap"
    "lv2"
    "vst"
    "vst3"
    "ladspa"
    "dssi"
  ];

  defaultProductionPackages =
    pkgs: with pkgs; [
      alsa-utils
      sox
      wineWow64Packages.stable
      yabridge
      yabridgectl
      # ZL Audio plugins (https://github.com/ZL-Audio) — modern open-source
      # VST3/LV2/CLAP processors. zlsplitter is the multi-band split that
      # zlequalizer + zlcompressor are designed to feed into.
      zlequalizer
      zlcompressor
      zlsplitter
    ];

  mkHomePluginLinks =
    {
      config,
      pluginDirs ? defaultPluginDirs,
    }:
    builtins.listToAttrs (
      map (dir: {
        name = ".${dir}/nixos";
        value.source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/${dir}";
      }) pluginDirs
    );
in
{
  inherit defaultPluginDirs defaultProductionPackages mkHomePluginLinks;
}
