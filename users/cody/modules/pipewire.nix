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
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Graph quantum = a device's default/idle latency. Kept SAFE/high (1024,
      # ~21 ms) so everyday audio (browser/system) stays glitch-free even on a
      # shared USB bus. Low latency is requested ON DEMAND per-app: the guitar
      # rig launches with PIPEWIRE_LATENCY=128/48000 (signal's `just rig`), which
      # pulls its interface down to ~2.7 ms only while it runs, then idles back
      # here. min-quantum 32 permits that pull-down.
      home.file.".config/pipewire/pipewire.conf.d/50-quantum.conf".text = ''
        context.properties = {
            default.clock.quantum     = 1024
            default.clock.min-quantum = 32
            default.clock.max-quantum = 2048
        }
      '';
    };
}
