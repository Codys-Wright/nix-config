# Hardware parametric aspect
# Common hardware (audio, bluetooth, networking, facter) always included.
# Opt in to machine-specific components: nvidia, tailscale, cuda.
#
# Usage: (FTS.hardware { nvidia = true; tailscale = true; })
{
  lib,
  den,
  FTS,
  __findFile,
  ...
}:
{
  FTS.hardware.description = "Hardware support configuration";

  FTS.hardware.__functor =
    _self:
    {
      nvidia ? false,
      tailscale ? false,
      cuda ? false,
      ...
    }:
    den.lib.parametric {
      includes = [
        <FTS.hardware/facter>
        <FTS.hardware/audio>
        <FTS.hardware/bluetooth>
        <FTS.hardware/networking>
        <FTS.hardware/disk-utils>
      ]
      ++ lib.optional tailscale <FTS.hardware._.networking/tailscale>
      ++ lib.optional nvidia <FTS.hardware/nvidia>
      ++ lib.optional cuda <FTS.hardware/cuda>;
    };
}
