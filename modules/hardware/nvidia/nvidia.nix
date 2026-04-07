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

          # Use the NVidia open source kernel module (not to be confused with the
          # independent third-party "nouveau" open source driver).
          # Support is limited to the Turing and later architectures. Full list of
          # supported GPUs is at:
          # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
          # Only available from driver 515.43.04+
          # Disabled due to build failures with kernel 6.17.9+
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
