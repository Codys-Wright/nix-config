# Per-user PipeWire config.
#
# The per-user PipeWire daemon does NOT read the system /etc/pipewire drop-ins
# (those only apply to a system-wide instance), so any user-facing quantum /
# latency config must live in ~/.config/pipewire to actually take effect. This
# is the declarative home-manager home for that — the user-pipewire equivalent
# of the host's /etc 92-low-latency.
{ ... }:
{
  cody.pipewire.description = "Cody's per-user PipeWire quantum / latency config";
  cody.pipewire.homeManager =
    { pkgs, lib, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
      let
        # ── Inferno Dante soundcard nodes (pairs with the host's
        # <fleet.music/production/inferno> aspect on THEBATTLESHIP) ────────────
        # The host aspect's homeManager block does NOT propagate to the home
        # under den (a host-included aspect contributes nixos only), so the
        # per-user PipeWire pieces Inferno needs live here, in cody's home.
        #
        # channels/card/headroom mirror the inferno aspect call in
        # hosts/THEBATTLESHIP/THEBATTLESHIP.nix (channels = 64, card = 999,
        # headroom = 128). On hosts without the Inferno ALSA PCM these adapter
        # nodes simply fail to open and stay suspended — harmless.
        infernoChannels = 64;
        infernoCard = 999;
        # 128 (not 0/32): the extra ALSA buffer absorbs scheduling jitter
        # that otherwise clicks — until kernel core isolation lands, this
        # is the stable value. (Tested 0→clamped-32 on 2026-07-21: lower
        # latency but occasional clicks under desktop load.)
        infernoHeadroom = 128;
        positions = lib.replicate infernoChannels "UNK";
        mkInfernoNode =
          {
            factoryName,
            nodeName,
            desc,
            mediaClass,
            alsaPath,
            prio,
            prioDriver,
          }:
          {
            factory = "adapter";
            args = {
              "factory.name" = factoryName;
              "node.name" = nodeName;
              "node.description" = desc;
              "media.class" = mediaClass;
              "api.alsa.path" = alsaPath;
              "api.alsa.pcm.card" = toString infernoCard;
              "api.alsa.headroom" = toString infernoHeadroom;
              # Small period = fine-grained pacing. The inferno PCM is a
              # virtual plugin over the PTP ring — no hardware IRQ cost —
              # so 32 keeps device-side buffering minimal while the graph
              # cycles at its own quantum (128). (Default was 1024 ≈21ms,
              # the single biggest latency chunk on the Dante path.)
              "api.alsa.period-size" = 32;
              "audio.channels" = infernoChannels;
              "audio.position" = positions;
              "priority.session" = prio;
              # CLOCK LEADER: the Inferno's pacing IS Dante PTP (statime
              # disciplines the ring buffer), so it must WIN the driver
              # election — above the Yamaha TF's 10000 — or the graph
              # runs on the TF's USB crystal and the Inferno path slowly
              # drifts (rising pitch, then stutter: two free-running 48k
              # clocks with no rate-matching between driver domains).
              # With Inferno driving, TF/REAPER become followers and
              # PipeWire rate-matches them to the Dante clock.
              # CAVEAT: with dante.target OFF this clock is invalid —
              # stop/suspend the Inferno nodes (or `dante off`) and the
              # TF (10000) takes the election back as fallback.
              "priority.driver" = prioDriver;
              "session.suspend-timeout-seconds" = 0;
              "node.pause-on-idle" = false;
              "node.suspend-on-idle" = false;
              "node.always-process" = true;
              "object.linger" = true;
              # Visible to JACK so Reaper (and qpwgraph etc.) can see and route
              # the Dante TX/RX ports directly. The `daw-link` helper +
              # dante-daw-autolink service snap Reaper to a clean 64x64
              # mapping; manual rewiring stays possible for the "connect
              # whatever" case.
              "jack.show" = true;
            };
          };

        # Snap Reaper's 128 in/out to the Inferno Dante soundcard, 1:1, with
        # two node-to-node pw-links (Reaper outs -> Dante TX, Dante RX -> Reaper
        # ins). Auto-detects Reaper's JACK node so it's robust to naming.
        dawLink = pkgs.writeShellApplication {
          name = "daw-link";
          runtimeInputs = [
            pkgs.pipewire
            pkgs.gnugrep
          ];
          text = ''
            reaper=$(pw-link -o 2>/dev/null | grep -ioE '^[^:]*reaper[^:]*' | head -1 || true)
            if [ -z "$reaper" ]; then
              echo "daw-link: no Reaper JACK client found (is Reaper on PipeWire/JACK?)" >&2
              exit 1
            fi
            # Clear any prior links — including the old all-ports node-to-node
            # links that wrongly bridged Reaper's MIDI ports and offset the
            # audio channel mapping.
            pw-link -d "$reaper" "Inferno sink"   2>/dev/null || true
            pw-link -d "Inferno source" "$reaper" 2>/dev/null || true
            # AUDIO-ONLY 1:1: out<N> -> playback_<N>, capture_<N> -> in<N>.
            # MIDI ports are never named out<N>/in<N>, so they're skipped.
            linked=0
            n=1
            while [ "$n" -le 128 ]; do
              if pw-link "$reaper:out$n" "Inferno sink:playback_$n" 2>/dev/null; then
                linked=$((linked + 1))
              fi
              pw-link "Inferno source:capture_$n" "$reaper:in$n" 2>/dev/null || true
              n=$((n + 1))
            done
            if [ "$linked" -eq 0 ]; then
              # Fallback: Reaper isn't using out<N>/in<N> names — link its
              # non-MIDI audio ports in numeric order instead.
              i=1
              while IFS= read -r p; do
                [ "$i" -le 128 ] && pw-link "$p" "Inferno sink:playback_$i" 2>/dev/null || true
                i=$((i + 1))
              done < <(pw-link -o 2>/dev/null | grep -F "$reaper:" | grep -viE 'midi' | sort -V)
              i=1
              while IFS= read -r p; do
                [ "$i" -le 128 ] && pw-link "Inferno source:capture_$i" "$p" 2>/dev/null || true
                i=$((i + 1))
              done < <(pw-link -i 2>/dev/null | grep -F "$reaper:" | grep -viE 'midi' | sort -V)
            fi
            echo "daw-link: $reaper audio 1:1 <-> Inferno Dante (MIDI excluded)"
          '';
        };

        # Point the "Talkback In" virtual mic at any source (a Dante channel or
        # a USB mic). EasyEffects processes "Talkback In" into a clean virtual
        # microphone ("EasyEffects Source") that Discord/etc. select as a device.
        talkbackSrc = pkgs.writeShellApplication {
          name = "talkback-src";
          runtimeInputs = [
            pkgs.pipewire
            pkgs.gnugrep
            pkgs.gnused
          ];
          text = ''
            sink="Talkback In"
            spec="''${1:-}"
            state="''${XDG_RUNTIME_DIR:-/tmp}/talkback-src.state"
            if [ -z "$spec" ]; then
              echo "usage: talkback-src <dante-channel# | source-name>"
              echo "  talkback-src 42    # Dante engineer mic (Inferno capture_42)"
              echo "  talkback-src usb   # first source whose name matches 'usb'"
              exit 1
            fi
            if printf '%s' "$spec" | grep -qE '^[0-9]+$'; then
              out="Inferno source:capture_$spec"
            else
              out=$(pw-link -o 2>/dev/null | grep -iE "$spec" \
                    | grep -viE "$sink|monitor|easyeffects" | head -1)
            fi
            [ -z "$out" ] && { echo "talkback-src: no source matching '$spec'" >&2; exit 1; }
            inp=$(pw-link -i 2>/dev/null | grep -F "$sink:" | head -1)
            [ -z "$inp" ] && { echo "talkback-src: '$sink' device not found (is PipeWire up?)" >&2; exit 1; }
            # swap cleanly: drop the previous feed, then connect the new one
            [ -f "$state" ] && pw-link -d "$(cat "$state")" "$inp" 2>/dev/null || true
            if pw-link "$out" "$inp" 2>/dev/null; then echo "$out" > "$state"; fi
            echo "talkback-src: $out -> $sink   (in Discord pick 'EasyEffects Source')"
          '';
        };

        # ── App-facing routed loopback sinks ────────────────────────────────
        # A stereo virtual sink (e.g. "System Audio") that apps select as their
        # output, whose two channels are pinned to a SPECIFIC Inferno TX pair.
        # You cannot just point a stereo app at the raw `Inferno sink`: its 128
        # channels are all `UNK`, so PipeWire has no FL/FR target to map onto
        # and routes silence. Each routed sink presents a clean stereo device
        # and a hidden passive `<name>_to_inferno` playback node whose ports are
        # pw-linked to Inferno `playback_<txL/txR>` by studio-routing-links.
        # Channel pairs follow the THEBATTLESHIP chan map (97/98 = System L/R →
        # Galaxy32 RX 61/62; 101/102 = Voice Chat L/R → Galaxy32 RX 63/64).
        # These sinks feed an Inferno TX pair DIRECTLY. Sub-sinks that feed
        # another app sink (so the parent fader controls them) go in `subSinks`.
        routedSinks = [
          {
            name = "system_audio";
            desc = "System Audio";
            txL = 57;
            txR = 58;
          }
          {
            name = "voice_chat";
            desc = "Voice Chat";
            txL = 59;
            txR = 60;
          }
        ];
        # App-facing sinks that feed ANOTHER app sink instead of a Dante TX pair.
        # `games` → `system_audio`: game audio rides the System Audio bus, so the
        # System Audio fader also controls game volume and both hit Inferno TX
        # 97/98 as one mix. (This is why there is no separate Games TX pair.)
        subSinks = [
          {
            name = "games";
            desc = "Games";
            targetSink = "system_audio";
          }
        ];
        # node.autoconnect=false stops WirePlumber's policy from linking the
        # passive `_to_inferno` side to the default sink (and growing its port
        # count to 128 to match). studio-routing-links makes the real links.
        dontAutoconnect = {
          "node.autoconnect" = false;
          "node.dont-reconnect" = true;
        };
        mkRoutedSink =
          {
            name,
            desc,
            txL,
            txR,
          }:
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = desc;
              # App-facing side: a proper FL/FR stereo sink apps can select.
              "capture.props" = {
                "node.name" = name;
                "node.description" = desc;
                "media.class" = "Audio/Sink";
                "audio.channels" = 2;
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                "monitor.channel-volumes" = true;
                "node.pause-on-idle" = false;
                "object.linger" = true;
              };
              # Hidden side: its output_1/output_2 are pinned to Inferno TX
              # txL/txR. UNK positions so the ports are plain output_1/output_2.
              "playback.props" = dontAutoconnect // {
                "node.name" = "${name}_to_inferno";
                "node.description" = "${desc} → Inferno TX ${toString txL}/${toString txR}";
                "audio.channels" = 2;
                "audio.position" = [
                  "UNK"
                  "UNK"
                ];
                "node.passive" = true;
                "object.linger" = true;
              };
            };
          };
        # A sub-sink is the same loopback shape, but its hidden playback side is
        # FL/FR (not UNK) and gets pinned to the TARGET SINK's FL/FR inputs
        # instead of an Inferno TX pair — so everything played into it rides the
        # target sink's fader before that sink forwards to Dante.
        mkSubSink =
          {
            name,
            desc,
            targetSink,
          }:
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = desc;
              "capture.props" = {
                "node.name" = name;
                "node.description" = desc;
                "media.class" = "Audio/Sink";
                "audio.channels" = 2;
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                "monitor.channel-volumes" = true;
                "node.pause-on-idle" = false;
                "object.linger" = true;
              };
              "playback.props" = dontAutoconnect // {
                "node.name" = "${name}_to_${targetSink}";
                "node.description" = "${desc} → ${targetSink}";
                "audio.channels" = 2;
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                "node.passive" = true;
                "object.linger" = true;
              };
            };
          };
        sinkLinkPairs = builtins.concatMap (s: [
          {
            out = "${s.name}_to_inferno:output_1";
            inp = "Inferno sink:playback_${toString s.txL}";
          }
          {
            out = "${s.name}_to_inferno:output_2";
            inp = "Inferno sink:playback_${toString s.txR}";
          }
        ]) routedSinks;
        # Pin each sub-sink's hidden playback ports to its target sink's FL/FR
        # inputs (a stereo Audio/Sink exposes playback_FL / playback_FR).
        subSinkLinkPairs = builtins.concatMap (s: [
          {
            out = "${s.name}_to_${s.targetSink}:output_FL";
            inp = "${s.targetSink}:playback_FL";
          }
          {
            out = "${s.name}_to_${s.targetSink}:output_FR";
            inp = "${s.targetSink}:playback_FR";
          }
        ]) subSinks;
        allLinkPairs = sinkLinkPairs ++ subSinkLinkPairs;
        # Every node both endpoints of a link live on must exist before we
        # pw-link, or the link silently no-ops. The loopback `_to_inferno`
        # nodes register asynchronously and LATER than the Inferno sink — during
        # a self-heal's pipewire churn the gap is several seconds — so wait for
        # ALL of them, not just the Inferno sink (that race left System Audio
        # unlinked after a heal: links to 97/98 never formed).
        requiredNodes = [
          "Inferno sink"
        ]
        ++ map (s: "${s.name}_to_inferno") routedSinks
        # Sub-sinks: both the hidden playback node AND the target sink it links
        # into (e.g. the "system_audio" app sink) must exist before we pw-link.
        ++ map (s: "${s.name}_to_${s.targetSink}") subSinks
        ++ map (s: s.targetSink) subSinks;
        # studio-routing-links: WirePlumber 0.5 has no static-link config and
        # PipeWire's link-factory fails fatally if target ports don't exist at
        # startup (loopback nodes register asynchronously). The reliable pattern
        # is pw-link from a unit that waits for the nodes and retries.
        routingLinks = pkgs.writeShellApplication {
          name = "studio-routing-links";
          runtimeInputs = [
            pkgs.pipewire
            pkgs.gnugrep
            pkgs.coreutils
          ];
          text = ''
            # Wait (up to ~90s) for ALL endpoint nodes — the Inferno sink AND
            # every loopback `_to_inferno` node — to register before linking.
            # The Inferno sink's ALSA plugin spins up its Dante DeviceServer
            # first; the loopback nodes appear a few seconds later still.
            for _ in $(seq 1 90); do
              nodes=$(pw-cli ls Node 2>/dev/null)
              missing=0
              ${lib.concatMapStringsSep "\n              " (
                n: ''printf '%s' "$nodes" | grep -q 'node.name = "${n}"' || missing=1''
              ) requiredNodes}
              [ "$missing" = 0 ] && break
              sleep 1
            done
            # try_link: retry per pair; "exists" counts as success.
            try_link() {
              out="$1"; inp="$2"
              for _ in $(seq 1 15); do
                msg=$(pw-link "$out" "$inp" 2>&1) && return 0
                case "$msg" in *exists*) return 0 ;; esac
                sleep 1
              done
              echo "studio-routing-links: failed after retries: $out -> $inp ($msg)" >&2
              return 0
            }
            ${lib.concatMapStringsSep "\n" (p: ''try_link "${p.out}" "${p.inp}"'') allLinkPairs}
          '';
        };
      in
      {
        # Graph quantum = PipeWire's processing block size. Matched to the TF's
        # ALSA period-size (128) so the graph, hardware, and pulse apps all run
        # at the same block size — no adapter chop/accumulation overhead.
        # min-quantum 32 still permits apps like guitarix to request lower latency.
        home.file.".config/pipewire/pipewire.conf.d/50-quantum.conf".text = ''
          context.properties = {
              # 128 @ 48k = 2.67ms per graph crossing. 2026-07-21: back down
              # from 256 — the old q128 failure was under the single-isolated-
              # core setup + REAPER-on-ALSA-resampler; now REAPER is a native
              # JACK follower of the Dante-clocked graph (no resampler on the
              # path) and rt-pin spreads data-loop/flows across two physical
              # cores. If load-spike clicks return, first suspect is q128.
              default.clock.quantum     = 128
              default.clock.min-quantum = 128
              default.clock.max-quantum = 1024
              # log.level 3 = info+debug; shows spa.alsa resync, xrun, pointer
              # drift events. Raise to 4 for trace-level scheduling noise.
              log.level                 = 3
          }
        '';

        # Inferno adapter nodes loaded directly in the MAIN per-user PipeWire.
        # The standalone `inferno-nodes` `pipewire -c` process (host aspect) runs
        # in an isolated context and never exports its nodes to this graph, so we
        # declare them here where apps/pw-link can actually reach them. They show
        # up as `Inferno sink` / `Inferno source` with 128 TX/RX ports.
        home.file.".config/pipewire/pipewire.conf.d/91-inferno-nodes.conf".text = builtins.toJSON {
          "context.objects" = [
            (mkInfernoNode {
              factoryName = "api.alsa.pcm.sink";
              nodeName = "Inferno sink";
              desc = "Inferno Dante Sink";
              mediaClass = "Audio/Sink";
              alsaPath = "inferno_sink";
              prio = 2000;
              # Below the source: the RX ring's PTP-paced arrivals make a
              # steadier driver than the TX side (sink-led graphs showed
              # 300-600us wakeup jitter; source-led ran clean).
              prioDriver = 19000;
            })
            (mkInfernoNode {
              factoryName = "api.alsa.pcm.source";
              nodeName = "Inferno source";
              desc = "Inferno Dante Source";
              mediaClass = "Audio/Source";
              alsaPath = "inferno_source";
              prio = 1900;
              # CLOCK LEADER (above TF's 10000 and the sink's 19000): the
              # source's RX ring is paced by steady PTP arrivals.
              prioDriver = 20000;
            })
          ];
        };

        # Routed loopback sinks (System Audio → Inferno TX 57/58, etc). The
        # loopback nodes register here; studio-routing-links.service pins their
        # output ports to the Inferno TX channels once the graph is up.
        home.file.".config/pipewire/pipewire.conf.d/93-studio-routing.conf".text = builtins.toJSON {
          "context.modules" = map mkRoutedSink routedSinks ++ map mkSubSink subSinks;
        };

        # Wire the routed loopback sinks to their Inferno TX channels. PartOf
        # pipewire.service so it re-links after every pipewire (re)start — the
        # links are torn down whenever the Inferno nodes are re-opened (e.g. by
        # studio-clock-ready's self-heal restarts).
        systemd.user.services.studio-routing-links = {
          Unit = {
            Description = "Pin studio loopback sinks to their Inferno TX channels";
            After = [ "pipewire.service" ];
            Wants = [ "pipewire.service" ];
            PartOf = [ "pipewire.service" ];
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${routingLinks}/bin/studio-routing-links";
          };
        };

        # The per-user `pipewire.service` SystemCallFilter allowlist omits
        # `@clock` (`clock_adjtime`/`clock_settime`/`adjtimex`), which the
        # inferno_aoip ALSA plugin needs to read the PTP clock. Without it the
        # device server can't obtain a ring-buffer start timestamp → TX/RX abort
        # with `RecvError` and the Inferno device restart-loops forever.
        # Upstream documents this exact requirement in
        # `os_integration/systemd_allow_clock.conf`. `ALSA_PLUGIN_DIR` lets the
        # main daemon locate the bundled inferno ALSA plugin.
        home.file.".config/systemd/user/pipewire.service.d/inferno-clock.conf".text = ''
          [Service]
          SystemCallFilter=@clock
          Environment=ALSA_PLUGIN_DIR=/run/current-system/sw/lib/alsa-lib
        '';

        # RT thread placement (revised twice, 2026-06-26):
        #  1. The old CPUAffinity=15 drop-in pinned the WHOLE pipewire process to
        #     one core — its SCHED_OTHER control thread got starved under the
        #     64x64 Dante load → GUI stutters.
        #  2. Pinning ALL SCHED_FIFO threads (data-loop + the inferno `flows TX`/
        #     `flows RX`) onto the isolated SMT pair 15,31 then caused graph xruns
        #     (popping/looping on Inferno RX): the heavy flow threads contend with
        #     the data-loop on the SAME physical core (15/31 are SMT siblings).
        #  3. Putting the flows on the NORMAL pool (off the isolated core) fixed
        #     the xruns but reintroduced GUI stutters — SCHED_FIFO flows preempt
        #     the desktop wherever they land.
        # FINAL split (2026-06-27): isolate TWO physical cores of CCD1
        # (rt-isolation cores = 14,15,30,31). data-loop.0 -> phys core 15 (SMT
        # 15,31); inferno flows -> phys core 14 (SMT 14,30). Separate physical
        # cores → no SMT contention (no xruns) AND both off the GUI/games cores
        # (no stutter). Control thread stays on the normal pool (no process-wide
        # CPUAffinity). Daemon re-scans every 5s, check-before-set so it never
        # needlessly perturbs a correctly-placed hard-RT thread.
        systemd.user.services.pipewire-rt-pin = {
          Unit = {
            Description = "Place PipeWire RT threads: data-loop on phys core 15, flows on phys core 14 (both isolated)";
            After = [ "pipewire.service" ];
            Wants = [ "pipewire.service" ];
          };
          # RE-ENABLED 2026-07-21: sink-led Dante graphs showed 300-600us
          # driver wakeup jitter (clicks/stutters). Kernel core isolation is
          # still off, so cores 14/15 aren't exclusive — but pinning the
          # data-loop and inferno flow threads still stops cross-CPU
          # migration jitter. Full determinism = rt-isolation aspect (reboot).
          Install.WantedBy = [ "default.target" ];
          Service = {
            Type = "simple";
            ExecStart = pkgs.writeShellScript "pipewire-rt-pin" ''
              set -u
              sctl=${pkgs.systemd}/bin/systemctl
              chrt=${pkgs.util-linux}/bin/chrt
              taskset=${pkgs.util-linux}/bin/taskset
              while true; do
                m=$("$sctl" --user show pipewire.service -p MainPID --value 2>/dev/null)
                if [ -n "$m" ] && [ "$m" != "0" ] && [ -d "/proc/$m/task" ]; then
                  for t in /proc/$m/task/*; do
                    tid=$(basename "$t")
                    "$chrt" -p "$tid" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q SCHED_FIFO || continue
                    comm=$(cat "$t/comm" 2>/dev/null || true)
                    # data-loop on isolated physical core 15 (SMT 15,31); the
                    # heavy inferno flows on the OTHER isolated physical core 14
                    # (SMT 14,30) — separate physical cores so they don't contend
                    # via SMT (that caused xruns/clicks). Both off the GUI cores.
                    case "$comm" in
                      data-loop*) want="15,31" ;;
                      flows*)     want="14,30" ;;
                      *)          continue ;;
                    esac
                    # check-before-set: only call sched_setaffinity when the
                    # placement is actually wrong, so we never perturb a hard-RT
                    # thread that's already correct (a needless taskset on the
                    # data-loop can nudge an xrun → REAPER stream desync → clicks).
                    cur=$("$taskset" -cp "$tid" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oE '[0-9,-]+$' || true)
                    [ "$cur" = "$want" ] || "$taskset" -cp "$want" "$tid" >/dev/null 2>&1 || true
                  done
                fi
                sleep 5
              done
            '';
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };

        # ── REAPER 64x64 ↔ Dante via ALSA (the working path) ──────────────
        # REAPER's ALSA backend pointed at the DUPLEX `inferno` device (one
        # device for BOTH in+out) opens a full 128 output + 128 input. A single
        # duplex device forces both directions to the same channel count; with
        # separate inferno_in/inferno_out REAPER opens input=128 but output=2.
        # ALSA has no patchbay, so these connections HOLD (JACK pruned them — it
        # re-asserts its whole connection state on every graph change). In
        # ~/.fts-dev/reaper.ini: linux_audio_mode=1, alsa_indev=inferno,
        # alsa_outdev=inferno, nch_in=nch_out=128. (See the
        # project-reaper-dante-64x64 memory for the full saga.)
        home.file.".asoundrc".text = ''
          # Inferno Dante 64ch via PipeWire, for REAPER's ALSA backend.
          # Use the duplex `inferno` for BOTH REAPER input and output devices.

          # Output only: REAPER 128 outs -> Inferno sink -> Dante TX
          pcm.inferno_out {
              type pipewire
              playback_node "Inferno sink"
              channels 64
              hint { show on description "Inferno Dante 64ch OUT (PipeWire)" }
          }
          # Input only: Dante RX -> Inferno source -> REAPER 128 ins
          pcm.inferno_in {
              type pipewire
              capture_node "Inferno source"
              channels 64
              hint { show on description "Inferno Dante 64ch IN (PipeWire)" }
          }
          # Duplex: one device, both directions — USE THIS in REAPER for 64x64.
          pcm.inferno {
              type pipewire
              playback_node "Inferno sink"
              capture_node "Inferno source"
              channels 64
              hint { show on description "Inferno Dante 64ch (PipeWire)" }
          }
          ctl.inferno { type pipewire }
        '';

        # `talkback-src` on PATH. (`daw-link` is a JACK helper — kept for ad-hoc
        # use, but the ALSA path above is what REAPER uses now, and the
        # dante-daw-autolink service that drove it is disabled below.)
        home.packages = [
          dawLink
          talkbackSrc
        ];

        # EasyEffects: DISABLED as an always-on service. It was running as a
        # global OUTPUT processor and hijacked the default sink — every app's
        # `default` (and REAPER's output) routed through `easyeffects_sink`
        # instead of Inferno, which broke "Inferno as default" and REAPER's
        # device resolution. The package stays installed (modules/music/
        # production/easyeffects.nix); launch it manually for talkback, and
        # before re-enabling always-on, configure it INPUT-only (process the
        # talkback mic, not all output) so it stops grabbing the default sink.
        services.easyeffects.enable = false;

        # "Talkback In" — a mono virtual mic you point at any source with
        # `talkback-src`. EasyEffects processes it; Discord selects the result.
        home.file.".config/pipewire/pipewire.conf.d/92-talkback-in.conf".text = builtins.toJSON {
          "context.objects" = [
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "Talkback In";
                "node.description" = "Talkback In";
                "media.class" = "Audio/Sink";
                "audio.position" = [ "MONO" ];
                "monitor.channel-volumes" = true;
                "object.linger" = true;
              };
            }
          ];
        };

        # Auto-link Reaper to the 64x64 Inferno mapping whenever it launches.
        # DISABLED (no Install.WantedBy): obsolete now that REAPER uses the ALSA
        # `inferno` device (it auto-routes to Inferno sink/source directly, no
        # patchbay). This JACK-era helper also had a bug — the inline script
        # called bare `head` with no PATH (writeShellScript), so it spammed
        # `head: command not found` and never linked anything. Kept defined for
        # reference; flip Install.WantedBy back on (and add coreutils to PATH)
        # only if you return REAPER to the JACK backend.
        systemd.user.services.dante-daw-autolink = {
          Unit = {
            Description = "Auto-link Reaper to the Inferno Dante soundcard (64x64)";
            After = [ "pipewire.service" ];
            Wants = [ "pipewire.service" ];
          };
          Service = {
            Type = "simple";
            ExecStart = pkgs.writeShellScript "dante-daw-autolink" ''
              prev=""
              while true; do
                r=$(${pkgs.pipewire}/bin/pw-link -o 2>/dev/null \
                      | ${pkgs.gnugrep}/bin/grep -ioE '^[^:]*reaper[^:]*' | head -1 || true)
                if [ -n "$r" ] && [ "$r" != "$prev" ]; then
                  sleep 1.5   # let all of Reaper's ports register
                  ${dawLink}/bin/daw-link || true
                  prev="$r"
                fi
                [ -z "$r" ] && prev=""
                sleep 2
              done
            '';
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      }
    );
}
