# Musnix real-time audio sub-aspect.
# Per-host knobs: den.hosts.<sys>.<host>.settings.hardware.audio.musnix.*
{
  fleet,
  lib,
  inputs,
  ...
}:
{
  flake-file.inputs.musnix.url = "github:musnix/musnix";

  fleet.hardware._.audio._.musnix = {
    description = "musnix real-time audio tuning (RT kernel options, limits, IRQ threading)";

    settings = {
      alsaSeq = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Load the ALSA sequencer kernel modules";
      };
      ffado = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "FireWire audio (FFADO)";
      };
      rtcqs = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install rtcqs (realtime config quick scan)";
      };
      soundcardPciId = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "00:1b.0";
        description = "PCI id of the soundcard to prioritise (empty = none)";
      };
    };

    nixos =
      { host, lib, ... }:
      let
        cfg = host.settings.hardware.audio.musnix;
      in
      {
        imports = [ inputs.musnix.nixosModules.musnix ];

        musnix = {
          enable = true;
          alsaSeq.enable = cfg.alsaSeq;
          ffado.enable = cfg.ffado;
          rtcqs.enable = cfg.rtcqs;
          soundcardPciId = lib.mkIf (cfg.soundcardPciId != "") cfg.soundcardPciId;
        };
      };
  };
}
