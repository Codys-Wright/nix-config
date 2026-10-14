# CUDA hardware aspect
{ fleet, ... }:
{
  fleet.hardware._.cuda = {
    description = "CUDA hardware support";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          pciutils
          cudatoolkit
        ];

        services.xserver.videoDrivers = [ "nvidia" ];

        # The CUDA team's binary cache (wiki.nixos.org/wiki/CUDA): prebuilt
        # cudaPackages (NCCL, NVSHMEM, cuDNN, …), so CUDA-enabled packages
        # aren't compiled from source.
        nix.settings.extra-substituters = [ "https://cache.nixos-cuda.org" ];
        nix.settings.extra-trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];

        # Note: nvidia-control-devices service is automatically created by NixOS's NVIDIA module
        # No need to manually define it - the hardware.nvidia configuration handles this
      };
  };
}
