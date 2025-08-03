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
  cfg = config.${namespace}.hardware.audio.pipewire;
in
{
  options.${namespace}.hardware.audio.pipewire = with types; {
    enable = mkBoolOpt false "Enable PipeWire audio system";
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;
    
    services.pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; [ pavucontrol helvum qpwgraph coppwr ];
  };
} 