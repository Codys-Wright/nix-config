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
  cfg = config.${namespace}.gaming;
in
{
  options.${namespace}.gaming = with types; {
    enable = mkBoolOpt false "Enable gaming modules";
    videoDriver = mkOpt (enum [ "nvidia" "amdgpu" ]) "nvidia" "Video driver to use for gaming";
  };

  config = mkIf cfg.enable {
    # Force OpenGL support for gaming
    hardware.opengl = {
      enable = mkForce true;
      driSupport = mkForce true;
      driSupport32Bit = mkForce true;
    };

    # Set video driver for gaming
    services.xserver.videoDrivers = mkForce [ cfg.videoDriver ];

    # Enable NVIDIA modesetting if nvidia driver is selected
    hardware.nvidia.modesetting.enable = mkIf (cfg.videoDriver == "nvidia") (mkForce true);

    ${namespace} = {
      gaming.lutris = mkDefault { enable = true; };
      gaming.steam = mkDefault { enable = true; };
      gaming.proton = mkDefault { enable = true; };
    };
  };
}
