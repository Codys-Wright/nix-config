{ den, ... }:
{
  den.aspects.THEBATTLESHIP-studio-routing = {
    description = "Studio PipeWire host config: quantum/pulse overrides, wireplumber seeding, watchdogs, clock-ready, DAW router (virtual nodes + channel links live in cody's home pipewire config)";
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
              # Inferno's ALSA virtual soundcard (hw_Controller_0) has
              # priority.driver = 2100 by default (same as TF capture),
              # so it wins the PipeWire clock-driver election by node-ID
              # tiebreak. With dante off its clock is invalid — any active
              # audio path produces white noise via the broken SRC.
              # Drop it below TF (2100) so TF always drives the graph clock.
              matches = [
                { "node.name" = "~alsa_(output|input)\\.hw_Controller_0"; }
              ];
              actions.update-props."priority.driver" = 500;
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

        # --- Clock-ready re-init ---
        #
        # PipeWire opens the Inferno ALSA node at boot, before statime has
        # locked the Dante PTP clock. Opened against a missing/invalid clock,
        # the node comes up frozen ("init" links, silent TX) and never
        # recovers on its own. So once statime is locked, bounce wireplumber
        # once: the Inferno node re-opens against the valid clock and
        # studio-routing-links (partOf wireplumber) re-wires the channels.
        # This is the one manual step that fixed a total Dante outage,
        # automated.
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
        # DISABLED 2026-06-26: the auto-restart did more harm than good. When
        # the Inferno 128ch device briefly blocks the core main loop (normal
        # during Dante churn / heavy 128ch streams), two missed 3s probes made
        # this restart the whole stack — which tears down the Inferno device
        # server (-> 0 TX/RX channels in Dante Controller) AND every client's
        # ports (REAPER output collapsed to 0/2ch). The restart cascade broke
        # Dante + REAPER repeatedly. The deadlock it was built for (REAPER JACK
        # `do_sync`) no longer applies now that REAPER uses the ALSA backend.
        # Left the service defined for manual `systemctl --user start
        # pipewire-watchdog` recovery, but no longer timer-driven.
        # systemd.user.timers.pipewire-watchdog = {
        #   wantedBy = [ "timers.target" ];
        #   timerConfig = {
        #     OnBootSec = "30s";
        #     OnUnitActiveSec = "10s";
        #   };
        # };

        systemd.user.services.studio-clock-ready = {
          description = "Re-init the audio session once the Dante PTP clock is locked";
          after = [
            "statime-inferno.service"
            "pipewire.service"
            "wireplumber.service"
          ];
          wants = [ "statime-inferno.service" ];
          # Gated behind dante.target — without the Dante network there is
          # no clock to wait for (and the wait would bounce wireplumber).
          partOf = [ "dante.target" ];
          wantedBy = [ "dante.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "studio-clock-ready" ''
              jctl=${pkgs.systemd}/bin/journalctl
              sctl=${pkgs.systemd}/bin/systemctl
              # Wait (up to ~2min) until statime is emitting Measurement
              # lines, i.e. locked as a PTP follower.
              for i in $(seq 1 60); do
                if [ "$("$jctl" --user -u statime-inferno.service --since '8 seconds ago' -o cat | grep -c 'Measurement:')" -gt 0 ]; then
                  break
                fi
                sleep 2
              done
              # Re-open the Inferno device against the now-valid clock AND
              # self-heal the device-server startup wedge.
              #
              # The Inferno adapter nodes live in pipewire's OWN config
              # (~/.config/pipewire/pipewire.conf.d/91-inferno-nodes.conf), so
              # they re-open only when PIPEWIRE restarts — NOT wireplumber
              # (the long-standing bug here: bouncing wireplumber never
              # re-opened Inferno). On a fraction of starts the inferno_aoip
              # DeviceServer comes up wedged: its ARC refuses connections (no
              # channel advertisement / can't manage subscriptions) even though
              # the data plane still flows. A fresh pipewire usually wins the
              # race within a couple tries, so restart-and-probe until the ARC
              # actually answers. This runs at `dante on` (oneshot, before
              # REAPER), so the restarts are not disruptive.
              #
              # Probe the REAL ARC with an inferno-control query — NOT the
              # `channels_subscriber ... TimedOut` log lines: those keep firing
              # as harmless background noise even when the ARC is perfectly
              # healthy, so they are a FALSE wedge signal.
              ictl=/run/current-system/sw/bin/inferno-control
              healed=0
              for attempt in $(seq 1 5); do
                "$sctl" --user restart pipewire.service
                sleep 9
                # Exit code alone is a FALSE "healthy" signal: a wedged
                # DeviceServer still answers the ARC, so `channel list`
                # connects and exits 0 — but its channel_count / device_info
                # sub-queries fail and it reports "TX channels (0):". That is
                # exactly how this probe logged "healthy" at boot while the
                # server was wedged for 18h (tx=0/rx=0, no subscriptions
                # possible). Require a NON-ZERO TX channel count instead: that
                # number comes from the channel_count query, which only
                # succeeds once the server is actually serving channels.
                txcount="$("$ictl" --timeout 6 channel list 10.10.10.10 2>/dev/null \
                  | sed -n 's/^TX channels (\([0-9]\{1,\}\)).*/\1/p' | head -1)"
                if [ -n "$txcount" ] && [ "$txcount" -gt 0 ]; then
                  healed=1
                  break
                fi
                echo "Inferno DeviceServer wedged — reported '"''${txcount:-no}"' TX channels (attempt $attempt/5); retrying pipewire restart."
              done
              # Restart wireplumber to (a) re-enumerate the ALSA hardware cards
              # so Yamaha TF / HDMI / etc. are selectable as desktop outputs and
              # (b) re-wire REAPER<->Inferno (studio-routing-links is partOf
              # wireplumber). After the pipewire churn above, wireplumber
              # occasionally races the settling graph and loads ZERO cards
              # (desktop output disappears) — so verify cards came back and
              # retry if not.
              for wp in 1 2 3; do
                "$sctl" --user restart wireplumber.service
                sleep 5
                if [ "$(${pkgs.pipewire}/bin/pw-cli ls Device 2>/dev/null | grep -c alsa)" -gt 0 ]; then
                  break
                fi
                echo "wireplumber enumerated 0 ALSA cards (attempt $wp/3); retrying."
              done
              # Re-pin the studio loopback sinks (System Audio → Inferno TX
              # 97/98, etc) as the FINAL step, after all the pipewire +
              # wireplumber churn above has settled. studio-routing-links is
              # PartOf pipewire so it also fires on each restart during the
              # heal — but a later restart in this same heal tears those links
              # back down, leaving System Audio unlinked. This explicit run
              # (the unit waits for the loopback nodes to register, then
              # pw-links) is the one that sticks. --no-block so we don't hang
              # on its node-wait; it's idempotent ("link exists" = success).
              "$sctl" --user restart --no-block studio-routing-links.service 2>/dev/null || true
              if [ "$healed" = 1 ]; then
                echo "Inferno DeviceServer healthy."
              else
                echo "Inferno ARC still not responding after 5 retries; manual intervention may be needed."
              fi
            '';
          };
        };

        # --- DAW link router ---
        #
        # pipewire-jack 1.6 has no per-client mechanism to redirect the
        # `system:playback_*` alias — `is_port_default()` in
        # pipewire-jack.c only consults the GLOBAL `default.audio.sink`
        # metadata. REAPER (and other JACK DAWs) auto-connect their
        # outputs to whatever 128-channel sink they enumerate first,
        # which in our graph is the ALSA-backed `Inferno sink` and
        # therefore bypasses the `daw` proxy + per-channel renames that
        # daw_to_inferno applies (DAW L/R = TX 95/96, etc).
        #
        # Solution: a tiny rule-driven daemon that watches
        # `pw-mon` for new Link events and rewrites any
        #   <DAW_BINARY>:outN -> Inferno sink:playback_M
        # link into the equivalent
        #   <DAW_BINARY>:outN -> daw:playback_M
        # connection. The match list is declarative — adding Ardour,
        # Bitwig, etc. is one line each. Same rule applies in reverse
        # (input direction) if/when DAWs auto-connect Inferno source.
        systemd.user.services.daw-router =
          let
            dawBinaries = [
              "reaper"
              "ardour"
              "bitwig-studio"
              "Bitwig Studio"
              "harrison-mixbus"
              "qtractor"
              "rosegarden"
              "carla"
            ];
            # DAW isolation policy: a DAW client's only legal peers are
            # the `daw` Audio/Sink (output side) and `daw_inputs`
            # Audio/Source (capture side). ANY other connection — to
            # Inferno sink/source, Yamaha TF capture, webcams, etc. —
            # is treated as an erroneous JACK auto-connect and
            # rewritten/dropped by daw-router.
            dawOutputProxy = "daw";
            dawInputProxy = "daw_inputs";
            dawRouter = pkgs.writeShellScript "daw-router" ''
              set -u
              pwLink=${pkgs.pipewire}/bin/pw-link
              pwMon=${pkgs.pipewire}/bin/pw-mon
              pwDump=${pkgs.pipewire}/bin/pw-dump

              outProxy='${dawOutputProxy}'
              inProxy='${dawInputProxy}'

              # Map node-name -> application.process.binary from pw-dump
              # JSON; pw-cli's text listing omits some props for JACK
              # clients which broke the prior bash-only parser.
              declare -A nodeBin
              refresh_node_binaries() {
                nodeBin=()
                while IFS=$'\t' read -r name bin; do
                  [ -n "$name" ] || continue
                  [ -n "$bin" ] || continue
                  nodeBin["$name"]="$bin"
                done < <(
                  "$pwDump" Node 2>/dev/null \
                    | ${pkgs.jq}/bin/jq -r '
                        .[]
                        | select(.info != null and .info.props != null)
                        | [ .info.props["node.name"] // ""
                          , .info.props["application.process.binary"] // ""
                          ]
                        | @tsv
                      '
                )
              }

              is_daw_node() {
                local node="$1"
                local bin="''${nodeBin[$node]:-}"
                case "$bin" in
                  ${lib.concatMapStringsSep "|" (b: ''"${b}"'') dawBinaries}) return 0 ;;
                esac
                # Fallback: well-known DAW node names. application.process.binary
                # can be empty for JACK clients launched inside FHS wrappers.
                case "$node" in
                  REAPER|REAPER[0-9]*|"Bitwig Studio"|Ardour|ardour*|Qtractor|qtractor*) return 0 ;;
                esac
                return 1
              }

              # Extract the trailing integer from a port name. Handles
              # both PipeWire-native ("playback_42", "input_7") and
              # JACK-style port names ("out95", "in12") where the
              # number isn't underscore-separated.
              port_index() {
                local p="$1"
                # Strip everything up to the last run of digits.
                echo "$p" | ${pkgs.gnused}/bin/sed -nE 's/^.*[^0-9]([0-9]+)$/\1/p; t; s/^([0-9]+)$/\1/p'
              }

              rewrite_now() {
                refresh_node_binaries
                local pairs rewrites=0
                pairs=$("$pwLink" -lo 2>/dev/null \
                  | ${pkgs.gawk}/bin/awk '
                      /^[^[:space:]]/ { src=$0; next }
                      /-> / {
                        dst=$0; sub(/^[[:space:]]*\|-> /, "", dst);
                        printf "%s\t%s\n", src, dst;
                      }
                    ')
                while IFS=$'\t' read -r src dst; do
                  [ -n "$src" ] || continue
                  [ -n "$dst" ] || continue
                  local srcNode="''${src%%:*}" srcPort="''${src#*:}"
                  local dstNode="''${dst%%:*}" dstPort="''${dst#*:}"

                  # MIDI links are not audio routing — leave them alone.
                  # The daw/daw_inputs proxies are audio-only loopbacks, so
                  # rewriting a MIDI link onto them always fails and just
                  # disconnects the device (drums -> REAPER:MIDI Input N).
                  case "$srcNode $srcPort $dstPort" in
                    *Midi-Bridge*|*"MIDI Input"*|*"MIDI Output"*|*midi*) continue ;;
                  esac

                  # Output direction: DAW source -> anything other than the
                  # daw proxy. Drop and re-target onto daw:playback_<N>.
                  if is_daw_node "$srcNode" && [ "$dstNode" != "$outProxy" ]; then
                    local n
                    n=$(port_index "$srcPort")
                    "$pwLink" -d "$src" "$dst" >/dev/null 2>&1 || true
                    if [ -n "$n" ] && [ "$n" -eq "$n" ] 2>/dev/null \
                       && "$pwLink" "$src" "$outProxy:playback_$n" >/dev/null 2>&1; then
                      echo "daw-router: OUT $src ->/ $dst => $outProxy:playback_$n" >&2
                    else
                      echo "daw-router: OUT $src ->/ $dst (dropped)" >&2
                    fi
                    rewrites=$((rewrites + 1))
                    continue
                  fi

                  # Input direction: anything other than the daw_inputs
                  # source -> DAW node. Drop and re-target onto
                  # daw_inputs:capture_<N>.
                  if is_daw_node "$dstNode" && [ "$srcNode" != "$inProxy" ]; then
                    local n
                    n=$(port_index "$dstPort")
                    "$pwLink" -d "$src" "$dst" >/dev/null 2>&1 || true
                    if [ -n "$n" ] && [ "$n" -eq "$n" ] 2>/dev/null \
                       && "$pwLink" "$inProxy:capture_$n" "$dst" >/dev/null 2>&1; then
                      echo "daw-router: IN  $src /-> $dst => $inProxy:capture_$n" >&2
                    else
                      echo "daw-router: IN  $src /-> $dst (dropped)" >&2
                    fi
                    rewrites=$((rewrites + 1))
                    continue
                  fi
                done <<< "$pairs"

                if [ "$rewrites" -gt 0 ]; then
                  echo "daw-router: $rewrites rewrites this pass" >&2
                fi
              }

              # Initial pass, then watch for relevant pw-mon events.
              # We only rescan when a *Link* is added/changed/removed,
              # not on every node/port event — pw-mon's event stream is
              # constant chatter from Inferno mDNS / etc and rescanning
              # on every line burns 100% CPU.
              rewrite_now
              last_run=$(date +%s)
              # pw-mon prints multi-line records:
              #   added:
              #   \tid: 123
              #   \ttype: PipeWire:Interface:Link/3
              # We can't easily filter to Link-only events without a
              # full parser, so just fire on every event header — the
              # 3 s debounce below caps the actual rescan rate.
              "$pwMon" 2>/dev/null \
                | ${pkgs.gawk}/bin/awk '/^(added|changed|removed):/{print; fflush()}' \
                | while read -r _evt; do
                    now=$(date +%s)
                    # Hard debounce: at most one rescan every 3 seconds.
                    # The libpipewire-jack auto-connect happens in bursts
                    # (REAPER registers 128 ports + connects them in a
                    # few hundred ms), so 3s catches the whole burst with
                    # one rewrite pass.
                    if [ $((now - last_run)) -ge 3 ]; then
                      rewrite_now
                      last_run=$now
                    fi
                  done
            '';
          in
          {
            description = "Rewrite DAW JACK auto-connects from Inferno sink onto the daw proxy";
            after = [ "pipewire.service" ];
            wants = [ "pipewire.service" ];
            bindsTo = [ "pipewire.service" ];
            partOf = [ "pipewire.service" ];
            wantedBy = [ "default.target" ];
            serviceConfig = {
              Type = "simple";
              Restart = "on-failure";
              RestartSec = 2;
              ExecStart = dawRouter;
            };
          };
      };
  };
}
