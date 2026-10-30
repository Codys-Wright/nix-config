# THEBATTLESHIP runs Loft's patched niri (niri-loft): stock niri 26.04 plus the
# `place-within-workspace` layer rule, so each workspace carries its own
# wallpaper (it slides with the workspace and shows in the overview). With no
# surface bound it behaves exactly like stock niri, so the other users' sessions
# are unaffected. Back to stock: drop this aspect from the host's includes.
#
# niri-loft-live (when the pinned Loft has it) is niri-loft that `loft dev live
# --niri` can swap for a checkout's build at the next login; without a dev build
# it is exactly niri-loft (with Loft's traffic lights).
{ inputs, ... }:
{
  den.aspects.THEBATTLESHIP-niri-loft = {
    description = "Loft's patched niri (per-workspace wallpapers) as the compositor";
    nixos =
      { lib, pkgs, ... }:
      {
        programs.niri.package =
          let
            loft = inputs.loft.packages.${pkgs.stdenv.hostPlatform.system};
          in
          lib.mkForce (loft.niri-loft-live or loft.niri-loft);
      };
  };
}
