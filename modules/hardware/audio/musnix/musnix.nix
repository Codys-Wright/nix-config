# Musnix real-time audio sub-aspect
# Takes named parameters for musnix configuration
{
  FTS,
  lib,
  inputs,
  ...
}: {
  flake-file.inputs.musnix.url = "github:musnix/musnix";

  # Function that produces a musnix real-time audio configuration aspect
  # Takes named parameters: { alsaSeq, ffado, rtcqs, soundcardPciId, ... }
  # Usage: (<FTS/hardware/audio/musnix> { rtcqs = true; })
  FTS.hardware._.audio._.musnix = {
    alsaSeq ? true,
    ffado ? false,
    rtcqs ? false,
    soundcardPciId ? "",
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    nixos = {
      pkgs,
      lib,
      ...
    }: {
      # Import musnix module
      imports = [inputs.musnix.nixosModules.musnix];

      # Configure musnix for real-time audio work
      musnix = {
        enable = true;
        alsaSeq.enable = alsaSeq;
        ffado.enable = ffado;
        rtcqs.enable = rtcqs;
        soundcardPciId = lib.mkIf (soundcardPciId != "") soundcardPciId;
      };
    };
  };
}
