# Audio effects plugins
{
  fleet,
  ...
}:
{
  fleet.music._.production._.plugins._.fx = {
    description = "Audio effects plugins for music production";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux (
          (with pkgs; [
            dragonfly-reverb
            lsp-plugins
            zlequalizer
            zlcompressor
            zlsplitter
            # Neural Amp Modeler — loads .nam capture models (the official
            # neuralampmodeler.com plugin recently rebranded to "Gateway"; this
            # is the community LV2 build, which loads the same .nam models and
            # works in REAPER as an LV2). Models live on the starcommand mount
            # (/mnt/starcommand). For the proprietary Gateway VST3/CLAP binary,
            # we'd need a separate fetch+autoPatchelf package.
            neural-amp-modeler-lv2
          ])
          ++ [
            pkgs.qpitch
            pkgs.dusk-audio-plugins
            pkgs.aether
            pkgs.tiagolr-time12
            pkgs.tiagolr-filtr
            pkgs.tiagolr-reevr
            pkgs.tiagolr-gate12
          ]
        );
      };
  };
}
