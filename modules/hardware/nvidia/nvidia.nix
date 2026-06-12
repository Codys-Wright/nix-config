# NVIDIA hardware aspect
{
  fleet,
  den,
  ...
}:
{
  fleet.hardware._.nvidia = {
    description = "NVIDIA graphics hardware support";

    includes = [ (den.lib.groups [ "video" ]) ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        hardware.graphics.enable = true;

        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.nvidia = {
          # Modesetting is required.
          modesetting.enable = true;

          package = config.boot.kernelPackages.nvidiaPackages.latest;

          # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
          # Enable this if you have graphical corruption issues or application crashes after waking
          # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
          # of just the bare essentials.
          powerManagement.enable = false;

          # Fine-grained power management. Turns off GPU when not in use.
          # Experimental and only works on modern Nvidia GPUs (Turing or newer).
          powerManagement.finegrained = false;

          # Open kernel module (NOT nouveau). Proprietary (open = false) was tested
          # for the 4-display / DSC + 2-Head-1-OR config but did not help; reverted.
          open = true;

          # Enable the Nvidia settings menu,
          # accessible via `nvidia-settings`.
          nvidiaSettings = true;
        };
      };
  };
}
