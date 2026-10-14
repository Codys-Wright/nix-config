# cody's desktop on THEBATTLESHIP: Loft (github:Codys-Wright/loft)
# as the niri shell. The other users keep the host's shell (Noctalia) and the
# login screen stays the host's — this is cody's alone.
{ ... }:
{
  den.aspects."cody@THEBATTLESHIP".homeManager.programs.loft = {
    enable = true;
    # No auto-lock and no monitor power-off for now: turning the monitors off
    # (DPMS) wedged the NVIDIA driver (nvidia-modeset hung in D state) and the
    # desktop never woke up. Re-enable once that's solved.
    idle.lockAfter = null;
    idle.screenOffAfter = null;
  };
}
