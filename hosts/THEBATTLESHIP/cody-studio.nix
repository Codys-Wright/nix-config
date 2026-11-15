# cody's studio PipeWire on THEBATTLESHIP — den host-qualified user aspect.
#
# `den.aspects."cody@THEBATTLESHIP"` applies to cody on THEBATTLESHIP only,
# in addition to den.aspects.cody: the per-user PipeWire quantum (matched to
# the TF's ALSA period) and the Talkback In virtual mic.
#
# Dante left this machine in 2026-11: a Raspberry Pi is the Dante interface
# and shows up here as a USB audio device. The Inferno nodes, the routed
# System Audio / Voice Chat / Games sinks, the RT pinning and REAPER's
# `inferno` .asoundrc are in git history if they are ever needed again.
#
# The per-user PipeWire daemon does NOT read the system /etc/pipewire
# drop-ins (those only apply to a system-wide instance), so user-facing
# quantum / latency config must live in ~/.config/pipewire.
{ ... }:
{
  den.aspects."cody@THEBATTLESHIP".description =
    "cody's THEBATTLESHIP studio PipeWire: quantum and the Talkback In mic";
  den.aspects."cody@THEBATTLESHIP".homeManager =
    { pkgs, lib, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
      let
        # Point the "Talkback In" virtual mic at any source (e.g. a USB mic).
        # EasyEffects processes "Talkback In" into a clean virtual microphone
        # ("EasyEffects Source") that Discord/etc. select as a device.
        talkbackSrc = pkgs.writeShellApplication {
          name = "talkback-src";
          runtimeInputs = [
            pkgs.pipewire
            pkgs.gnugrep
          ];
          text = ''
            sink="Talkback In"
            spec="''${1:-}"
            state="''${XDG_RUNTIME_DIR:-/tmp}/talkback-src.state"
            if [ -z "$spec" ]; then
              echo "usage: talkback-src <source-name pattern>"
              echo "  talkback-src usb   # first source whose name matches 'usb'"
              exit 1
            fi
            out=$(pw-link -o 2>/dev/null | grep -iE "$spec" \
                  | grep -viE "$sink|monitor|easyeffects" | head -1)
            [ -z "$out" ] && { echo "talkback-src: no source matching '$spec'" >&2; exit 1; }
            inp=$(pw-link -i 2>/dev/null | grep -F "$sink:" | head -1)
            [ -z "$inp" ] && { echo "talkback-src: '$sink' device not found (is PipeWire up?)" >&2; exit 1; }
            # swap cleanly: drop the previous feed, then connect the new one
            [ -f "$state" ] && pw-link -d "$(cat "$state")" "$inp" 2>/dev/null || true
            if pw-link "$out" "$inp" 2>/dev/null; then echo "$out" > "$state"; fi
            echo "talkback-src: $out -> $sink   (in Discord pick 'EasyEffects Source')"
          '';
        };
      in
      {
        # Graph quantum = PipeWire's processing block size. Matched to the TF's
        # ALSA period-size (128) so the graph, hardware, and pulse apps all run
        # at the same block size — no adapter chop/accumulation overhead.
        home.file.".config/pipewire/pipewire.conf.d/50-quantum.conf".text = ''
          context.properties = {
              # 128 @ 48k = 2.67ms per graph crossing.
              default.clock.quantum     = 128
              default.clock.min-quantum = 128
              default.clock.max-quantum = 1024
              # log.level 3 = info+debug; shows spa.alsa resync, xrun, pointer
              # drift events. Raise to 4 for trace-level scheduling noise.
              log.level                 = 3
          }
        '';

        home.packages = [ talkbackSrc ];

        # EasyEffects: not an always-on service. As a global OUTPUT processor
        # it hijacked the default sink (every app's `default` routed through
        # `easyeffects_sink`). The package stays installed (modules/music/
        # production/easyeffects.nix); launch it manually for talkback, and
        # configure it INPUT-only before making it always-on again.
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
      }
    );
}
