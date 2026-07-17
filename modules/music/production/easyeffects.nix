# EasyEffects — GUI PipeWire effects host (gate / EQ / compressor / de-esser /
# limiter / reverb …). Used here as the studio's live effects + the eventual
# talkback-mic processor.
#
# RT placement: EasyEffects processes through PipeWire filter nodes, so its DSP
# runs on the graph data-loop — which is pinned to the isolated RT core (15) by
# <fleet.hardware._.audio/rt-isolation>. No extra pinning needed for the audio
# thread; only the EasyEffects GUI/control process lives on the main cores.
#
# Talkback routing (wire when ready): a Dante RX channel (the talkback mic,
# e.g. Inferno source:capture_51 "Producer Talkback") -> EasyEffects input
# chain -> a Dante TX channel (Inferno sink:playback_N) to the monitors/console.
# `services.easyeffects.enable` (home-manager) can run it headless/always-on
# once the preset is dialed in.
{ fleet, ... }:
{
  fleet.music._.production._.easyeffects = {
    description = "EasyEffects — PipeWire effects host / talkback mic processor";
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.easyeffects ];
      };
  };
}
