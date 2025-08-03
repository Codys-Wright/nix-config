{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.audio.pipewire;
in
{
  options.${namespace}.hardware.audio.pipewire = with types; {
    enable = mkBoolOpt false "Enable PipeWire audio system";
    sampleRate = mkOpt int 48000 "Default sample rate for PipeWire";
    bufferSize = mkOpt int 32 "Default buffer size (quantum) for PipeWire";
    minBufferSize = mkOpt int 32 "Minimum buffer size for PipeWire";
    maxBufferSize = mkOpt int 32 "Maximum buffer size for PipeWire";
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;
    
    services.pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;

      # Low-latency configuration
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = cfg.sampleRate;
          "default.clock.quantum" = cfg.bufferSize;
          "default.clock.min-quantum" = cfg.minBufferSize;
          "default.clock.max-quantum" = cfg.maxBufferSize;
        };
      };

      # PulseAudio backend configuration for low latency
      extraConfig.pipewire-pulse."92-low-latency" = {
        context.modules = [
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              pulse.min.req = "${toString cfg.minBufferSize}/${toString cfg.sampleRate}";
              pulse.default.req = "${toString cfg.bufferSize}/${toString cfg.sampleRate}";
              pulse.max.req = "${toString cfg.maxBufferSize}/${toString cfg.sampleRate}";
              pulse.min.quantum = "${toString cfg.minBufferSize}/${toString cfg.sampleRate}";
              pulse.max.quantum = "${toString cfg.maxBufferSize}/${toString cfg.sampleRate}";
            };
          }
        ];
        stream.properties = {
          node.latency = "${toString cfg.bufferSize}/${toString cfg.sampleRate}";
          resample.quality = 1;
        };
      };
    };

    environment.systemPackages = with pkgs; [ 
      pavucontrol 
      helvum 
      qpwgraph 
      coppwr 
      (python3.withPackages (ps: with ps; [
        raysession
      ]))
    ];
  };
} 