# Inferno - unofficial Dante implementation
# System-wide PipeWire ALSA virtual soundcard for THEBATTLESHIP.
# One shared Dante device; all users route through the system PipeWire.
{ fleet, ... }:
{
  fleet.music._.production._.inferno = {
    description = "Inferno Dante tools and system-wide ALSA virtual soundcard";

    nixos =
      { pkgs, ... }:
      let
        infernoPkg = pkgs.callPackage ../../../packages/inferno/inferno.nix { };

        infernoStartSink = pkgs.writeShellScript "inferno-start-pipewire-sink" ''
          ${pkgs.pipewire}/bin/pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.sink node.name="Inferno sink" media.class=Audio/Sink api.alsa.path="inferno" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=128 api.alsa.pcm.card=999 }'
        '';

        infernoStartSource = pkgs.writeShellScript "inferno-start-pipewire-source" ''
          ${pkgs.pipewire}/bin/pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.source node.name="Inferno source" media.class=Audio/Source api.alsa.path="inferno" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=128 api.alsa.pcm.card=999 }'
        '';
      in
      {
        environment.systemPackages = [ infernoPkg ];
        environment.pathsToLink = [ "/lib/alsa-lib" ];
        environment.variables = {
          ALSA_PLUGIN_DIR = "/run/current-system/sw/lib/alsa-lib";
        };

        # Keep the clock group existing (nice for manual tools), even though
        # root-owned system-wide PipeWire does not need membership.
        users.groups.clock = { };

        # System-wide ALSA configuration for the shared Inferno device
        environment.etc."asound.conf".text = ''
          pcm!default { type null }
          ctl!default { type null }

          pcm.inferno {
            type inferno
            NAME "THEBATTLESHIP"
            DEVICE_ID "00000A0A0A0A0001"
            BIND_IP "10.10.10.10"
            # Leave CLOCK_PATH unset so Inferno follows Statime's exported usrvclock,
            # which in turn tracks the Dante/PTP grandmaster (Galaxy32).
            PROCESS_ID "1"
            ALT_PORT "4400"
            SAMPLE_RATE "48000"
            RX_CHANNELS "2"
            TX_CHANNELS "2"
            RX_LATENCY_NS "500000"
            TX_LATENCY_NS "500000"

            hint {
              show on
              description "THEBATTLESHIP Inferno virtual device"
            }
          }
        '';

        # Allow system-wide PipeWire (running as root) to call clock_adjtime for PTP.
        systemd.services.pipewire.serviceConfig.SystemCallFilter = [ "@clock" ];

        # System-wide Inferno sink (playback / Dante TX)
        systemd.services.inferno-pipewire-sink = {
          description = "Inferno Dante sink node for PipeWire";
          after = [
            "pipewire.service"
            "statime-inferno.service"
          ];
          requires = [ "pipewire.service" ];
          wants = [ "statime-inferno.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = [
              "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
              "ALSA_CONFIG_PATH=/etc/asound.conf"
              "XDG_RUNTIME_DIR=/run/pipewire"
            ];
            ExecStart = "${infernoStartSink}";
          };
        };

        # System-wide Inferno source (capture / Dante RX)
        systemd.services.inferno-pipewire-source = {
          description = "Inferno Dante source node for PipeWire";
          after = [
            "pipewire.service"
            "inferno-pipewire-sink.service"
            "statime-inferno.service"
          ];
          requires = [ "pipewire.service" ];
          wants = [ "statime-inferno.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = [
              "ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib"
              "ALSA_CONFIG_PATH=/etc/asound.conf"
              "XDG_RUNTIME_DIR=/run/pipewire"
            ];
            ExecStart = "${infernoStartSource}";
          };
        };
      };
  };
}
