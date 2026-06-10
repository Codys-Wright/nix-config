# NVIDIA hardware aspect
{ fleet, den, ... }:
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
        # Load all NVIDIA modules in initrd so the DRM device is ready before SDDM starts.
        # Without this, kwin_wayland races the driver and fails to find /dev/dri/card*.
        boot.initrd.kernelModules = [
          "nvidia"
          "nvidia_modeset"
          "nvidia_uvm"
          "nvidia_drm"
        ];

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

          # Open vs proprietary kernel module (NOT nouveau).
          # The OPEN module (595.71.05) fails to bring up a 4th display head
          # alongside the 5120x1440@240 OLED — that mode needs DSC + 2-Head-1-OR
          # (2 of the GPU's 4 heads), and the open module errors on the 4th
          # surface with "Invalid request parameters, planePitch ... surface
          # registration". The proprietary module has more mature DSC /
          # multi-head / surface-allocation handling. Trying it for the 4-display
          # config. (Already the newest version available; the module type is
          # the only meaningful lever here.)
          open = false;

          # Enable the Nvidia settings menu,
          # accessible via `nvidia-settings`.
          nvidiaSettings = true;

          # Use the default driver that matches the current kernel version
          # The proprietary driver (open = false) works better with newer kernels
        };
      };
  };
}
