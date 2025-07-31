{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.cuda;
in
{
  options.${namespace}.hardware.cuda = with types; {
    enable = mkBoolOpt false "Enable cuda module";
  };

  config = mkIf cfg.enable {
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
}
