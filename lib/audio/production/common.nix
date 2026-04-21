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

  defaultProductionPackages = pkgs: with pkgs; [
    alsa-utils
    sox
    wineWowPackages.stable
    yabridge
    yabridgectl
  ];

  mkHomePluginLinks =
    {
      config,
      pluginDirs ? defaultPluginDirs,
    }:
    builtins.listToAttrs (
      map (
        dir:
        {
          name = ".${dir}/nixos";
          value.source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/${dir}";
        }
      ) pluginDirs
    );
in
{
  inherit defaultPluginDirs defaultProductionPackages mkHomePluginLinks;
}
