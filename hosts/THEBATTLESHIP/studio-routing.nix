{ den, ... }:
{
  den.aspects.THEBATTLESHIP-studio-routing = {
    description = "Studio PipeWire host config: USB interface rules, quantum/pulse overrides, wireplumber seeding, core watchdog";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        services.pipewire = {
          wireplumber.extraConfig."80-pro-audio-usb"."monitor.alsa.rules" = [
            {
              matches = [
                { "device.name" = "~alsa_card.usb-Yamaha_Corporation_Yamaha_TF.*"; }
                { "device.name" = "~alsa_card.usb-Fractal_Audio.*"; }
              ];
              actions.update-props."api.alsa.use-acp" = false;
            }
            {
              # TF playback: limit to 2ch stereo to avoid PipeWire upmixing corruption.
              # The hardware has 34 channels but PipeWire's mixer can't safely convert
              # 2ch → 34ch (pads with garbage, causing interface errors after ~2sec).
              # Separate rule below handles the 34ch capture separately.
              matches = [
                { "node.name" = "~alsa_output\\.usb-Yamaha_Corporation_Yamaha_TF.*"; }
              ];
              actions.update-props = {
                "audio.channels" = 34;
                "session.suspend-timeout-seconds" = 0;
                "node.always-process" = true;
                "priority.driver" = 10000;
                "api.alsa.disable-mmap" = true;
                "api.alsa.disable-batch" = true;
                "api.alsa.period-size" = 128;
                "api.alsa.headroom" = 256;
              };
            }
            {
              # TF capture: 34 channels for loopback/monitoring from hardware
              matches = [
                { "node.name" = "~alsa_input\\.usb-Yamaha_Corporation_Yamaha_TF.*"; }
              ];
              actions.update-props = {
                "audio.channels" = 34;
                "session.suspend-timeout-seconds" = 0;
              };
            }
            {
              # Axe-FX III: 8-channel USB audio (FL FR FC LFE RL RR FLC FRC).
              # Without explicit channels the spa-alsa probe defaults to 64,
              # creating a 64-ch PipeWire node that maps audio to nowhere.
              matches = [
                { "node.name" = "~alsa_(output|input)\\.usb-Fractal_Audio.*"; }
              ];
              actions.update-props = {
                "audio.channels" = 8;
                "audio.position" = "FL,FR,FC,LFE,RL,RR,FLC,FRC";
              };
            }
          ];

          # Graph quantum = the device's default/idle latency. Kept SAFE/high
          # (1024, ~21 ms) so everyday audio (browser/system) stays glitch-free
          # on the shared USB bus. Low latency is requested ON DEMAND per-app:
          # the guitar rig launches with PIPEWIRE_LATENCY=128/48000 (signal's
          # `just rig`), which pulls the interface down to ~2.7 ms only while it
          # runs, then idles back here (min-quantum=32 permits it). mkForce
          # because the audio facet's default pipewire instance also sets this.
          extraConfig.pipewire."92-low-latency".context.properties."default.clock.quantum" = lib.mkForce 128;
          # Pulse request size matched to graph quantum so PulseAudio apps
          # don't request 256-sample blocks into a 128-sample graph.
          extraConfig.pipewire-pulse."92-low-latency"."pulse.properties"."pulse.default.req" =
            lib.mkForce "128/48000";
          extraConfig.pipewire-pulse."92-low-latency"."stream.properties"."node.latency" =
            lib.mkForce "128/48000";

          # Prevent stream clients from competing in the PipeWire clock
          # driver election. The jack.conf approach is ignored by Proton's
          # bundled pipewire libs; WirePlumber node.rules runs server-side
          # and applies regardless of which client library the app uses.
          # Belt-and-suspenders with the TF headroom increase below.
          wireplumber.extraConfig."91-no-stream-driver"."node.rules" = [
            {
              matches = [ { "media.class" = "~Stream/.*"; } ];
              actions.update-props."node.driver" = false;
            }
          ];

          # Disable the libcamera monitor. WirePlumber publishes every UVC
          # webcam + the MS2109 HDMI grabber as BOTH a libcamera node and a
          # v4l2 node; its built-in dedup is documented to fail on
          # multi-interface / "complex" devices (the grabber especially), so
          # two readers end up contending for one /dev/videoN — the cause of
          # OBS's "decoder: failed to unpack jpeg" and "select timed out".
          # Dropping libcamera leaves exactly one (v4l2, media.role=Camera)
          # node per device, which is what both the direct-V4L2 path and the
          # xdg-desktop-portal Camera path want. Per-user WirePlumber uses
          # the "main" profile.
          wireplumber.extraConfig."51-disable-libcamera"."wireplumber.profiles" = {
            main."monitor.libcamera" = "disabled";
          };

        };

        # WirePlumber persists "which profile is active for each card" in
        # ~pipewire/.local/state/wireplumber/default-profile. If a card's
        # entry says `off`, WP refuses to instantiate any sink/source for
        # it. We want the Yamaha TF console and the Ryzen onboard analog
        # to come up active on every boot, so seed those entries before
        # wireplumber starts. Cards we don't list (e.g. the Axe-Fx) keep
        # whatever the file previously had.
        systemd.user.services.wireplumber.serviceConfig.ExecStartPre =
          let
            seedScript = pkgs.writeShellScript "wireplumber-seed-profiles" ''
              set -u
              state="''${XDG_STATE_HOME:-$HOME/.local/state}/wireplumber/default-profile"
              mkdir -p "$(dirname "$state")"
              touch "$state"

              # (card-name, profile) pairs to enforce.
              # The TF has no USB serial number so WirePlumber may append .2
              # when the device is seen on a different port; seed both names.
              declare -A want=(
                ["alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00"]="on"
                ["alsa_card.usb-Yamaha_Corporation_Yamaha_TF-00.2"]="on"
                ["alsa_card.pci-0000_7a_00.6"]="output:analog-stereo+input:analog-stereo"
              )

              tmp=$(mktemp)
              # Keep the [default-profile] header and any keys we don't manage.
              if grep -q '^\[default-profile\]' "$state"; then
                cp "$state" "$tmp"
              else
                echo '[default-profile]' > "$tmp"
              fi

              for k in "''${!want[@]}"; do
                v="''${want[$k]}"
                if grep -qE "^$k=" "$tmp"; then
                  ${pkgs.gnused}/bin/sed -i "s|^$k=.*|$k=$v|" "$tmp"
                else
                  echo "$k=$v" >> "$tmp"
                fi
              done

              install -m 0644 "$tmp" "$state"
              rm -f "$tmp"
            '';
          in
          [ "${seedScript}" ];

        # ── PipeWire core watchdog ─────────────────────────────────────
        # pipewire 1.6's link-creation path can deadlock the core's main
        # loop against the data-loop lock during device churn (observed:
        # REAPER's jack_connect during Yamaha TF bring-up → core wedged →
        # REAPER stuck on launch forever). The watchdog probes the core
        # with a short-timeout pw-cli round-trip; two consecutive misses
        # restart the audio stack, which unblocks any client stuck in a
        # jack do_sync (the dead socket errors their call out).
        systemd.user.services.pipewire-watchdog = {
          description = "Restart PipeWire if its core stops answering";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "pipewire-watchdog" ''
              probe() {
                ${pkgs.coreutils}/bin/timeout 3 \
                  ${pkgs.pipewire}/bin/pw-cli info 0 >/dev/null 2>&1
              }
              if probe; then exit 0; fi
              # One retry to ride out a momentarily busy loop.
              sleep 2
              if probe; then exit 0; fi
              echo "PipeWire core unresponsive; restarting audio stack."
              ${pkgs.systemd}/bin/systemctl --user restart \
                pipewire.service wireplumber.service pipewire-pulse.service
            '';
          };
        };
        # Not timer-driven since 2026-06-26 (its automatic restarts did more
        # harm than good); run `systemctl --user start pipewire-watchdog` by hand.
        # systemd.user.timers.pipewire-watchdog = {
        #   wantedBy = [ "timers.target" ];
        #   timerConfig = {
        #     OnBootSec = "30s";
        #     OnUnitActiveSec = "10s";
        #   };
        # };
      };
  };
}
