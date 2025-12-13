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

          # Low-latency configuration
          extraConfig.pipewire."92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 32;
              "default.clock.min-quantum" = 32;
              "default.clock.max-quantum" = 32;
            };
          };

          # PulseAudio backend configuration for low latency
          extraConfig.pipewire-pulse."92-low-latency" = {
            context.modules = [
              {
                name = "libpipewire-module-protocol-pulse";
                args = {
                  pulse.min.req = "32/48000";
                  pulse.default.req = "32/48000";
                  pulse.max.req = "32/48000";
                  pulse.min.quantum = "32/48000";
                  pulse.max.quantum = "32/48000";
                };
              }
            ];
            stream.properties = {
              node.latency = "32/48000";
              resample.quality = 1;
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
