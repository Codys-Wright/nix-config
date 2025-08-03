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
    hardware.graphics = {
      enable = mkForce true;
      enable32Bit = mkForce true;
    };

    # Set video driver for gaming based on system GPU configuration
    services.xserver.videoDrivers = mkForce [ config.${namespace}.gpu.type ];

    # Enable NVIDIA modesetting if nvidia driver is selected
    hardware.nvidia.modesetting.enable = mkIf (config.${namespace}.gpu.type == "nvidia") (mkForce true);
    
    # Use NVIDIA beta drivers for better gaming performance
    hardware.nvidia.package = mkIf (config.${namespace}.gpu.type == "nvidia") (mkForce config.boot.kernelPackages.nvidiaPackages.beta);
    
    # Ensure nvidia-control-devices service uses the same beta drivers
    systemd.services.nvidia-control-devices.path = mkIf (config.${namespace}.gpu.type == "nvidia") (mkForce [ config.boot.kernelPackages.nvidiaPackages.beta ]);

    # Enable ntsync for better gaming performance
    boot.kernelModules = mkForce [ "ntsync" ];

    ${namespace} = {
      gaming.lutris = mkDefault { enable = true; };
      gaming.steam = mkDefault { enable = true; };
      gaming.proton = mkDefault { enable = true; };
    };
  };
}
