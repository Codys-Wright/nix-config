# Reusable Inferno aspect for Dante/ALSA virtual devices.
# Host-specific instances live here, but the implementation is parameterized in
# ./inferno/common.nix so other machines can import it with different channel
# counts, latencies, device IDs, bind IPs, and PCM names.
{ fleet, lib, ... }:
let
  mkInfernoAspect = import ../../../lib/inferno/common.nix { inherit lib; };
in
{
  fleet.music._.production._.inferno = mkInfernoAspect {
    name = "THEBATTLESHIP";
    bindIp = "10.10.10.10";
    deviceId = "00000A0A0A0A0001";
    description = "Inferno Dante tools and system-wide ALSA virtual soundcard";
    pcmName = "inferno";
    channels = 16;
    sampleRate = 48000;
    latencyNs = 1000000;
    headroom = 128;
    card = 999;
    periodSize = 1024;
    periodNum = 4;
  };
}
