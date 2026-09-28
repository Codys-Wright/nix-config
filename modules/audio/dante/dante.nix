# Dante AoIP tooling shared by any Dante-connected host. The device itself
# (Inferno virtual soundcard) and PTP clock (statime) take per-host network
# details, so hosts call them directly next to this facet.
{ fleet, ... }:
{
  fleet.audio._.dante = {
    description = "Dante AoIP tooling — netaudio + inferno-control (inferno/statime are per-host calls)";
    includes = [
      fleet.audio._.dante._.netaudio
      fleet.audio._.dante._.control
    ];
  };
}
