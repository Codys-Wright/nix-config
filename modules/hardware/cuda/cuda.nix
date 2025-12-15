# CUDA hardware aspect
{FTS, ...}: {
  FTS.hardware._.cuda = {
    description = "CUDA hardware support";

    nixos = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        pciutils
        cudatoolkit
      ];

      services.xserver.videoDrivers = ["nvidia"];

      # Note: nvidia-control-devices service is automatically created by NixOS's NVIDIA module
      # No need to manually define it - the hardware.nvidia configuration handles this
    };
  };
}
