# Hardware parametric aspect
# Common hardware (audio, bluetooth, networking, facter) always included.
# Opt in to machine-specific components: nvidia, tailscale, cuda.
#
# Usage: (fleet.hardware { nvidia = true; tailscale = true; })
{
  lib,
  den,
  fleet,
  __findFile,
  ...
}:
{
  fleet.hardware.description = "Hardware support configuration";

  fleet.hardware.__functor =
    _self:
    {
      nvidia ? false,
      tailscale ? false,
      cuda ? false,
      ...
    }:
    den.lib.parametric {
      includes = [
        <fleet.hardware/facter>
        <fleet.hardware/audio>
        <fleet.hardware/bluetooth>
        <fleet.hardware/networking>
        <fleet.hardware/disk-utils>
      ]
      ++ lib.optional tailscale <fleet.hardware._.networking/tailscale>
      ++ lib.optional nvidia <fleet.hardware/nvidia>
      ++ lib.optional cuda <fleet.hardware/cuda>;
    };
}
