# Exposes the niri wrapper settings as flake.wrapperModules.niri.
# The actual settings live in niri-settings.nix (pure module, no flake deps).
{ ... }:
{
  flake.wrapperModules.niri = import ./_niri-settings.nix;
}
