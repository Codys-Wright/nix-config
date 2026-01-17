# PipeWire audio sub-aspect (can be included independently)
{
  FTS,
  ...
}:
{
  FTS.hardware._.audio._.pipewire = {
    description = "PipeWire audio system with low-latency configuration";

    nixos =
      { pkgs, lib, ... }:
      {
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

          # Flexible latency configuration
          extraConfig.pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 256; # Default buffer (5.3ms)
              "default.clock.min-quantum" = 32; # Can go low for pro audio
              "default.clock.max-quantum" = 1024; # Can go high for stability
            };
          };

          # PulseAudio backend configuration with flexible latency
          extraConfig.pipewire-pulse."92-low-latency" = {
            context.modules = [
              {
                name = "libpipewire-module-protocol-pulse";
                args = {
                  pulse.min.req = "32/48000";
                  pulse.default.req = "256/48000";
                  pulse.max.req = "1024/48000";
                  pulse.min.quantum = "32/48000";
                  pulse.max.quantum = "1024/48000";
                };
              }
            ];
            stream.properties = {
              node.latency = "256/48000";
              resample.quality = 4;
            };
          };
        };

        environment.systemPackages = with pkgs; [
          pavucontrol
          helvum
          qpwgraph
          coppwr
        ];
      };
  };
}
