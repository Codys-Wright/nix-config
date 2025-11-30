# CUDA hardware aspect
{
  FTS,
  ...
}:
{
  FTS.cuda = {
    description = "CUDA hardware support";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        pciutils
        cudatoolkit
      ];

      services.xserver.videoDrivers = [ "nvidia" ];

      systemd.services.nvidia-control-devices = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
      };
    };
  };
}

