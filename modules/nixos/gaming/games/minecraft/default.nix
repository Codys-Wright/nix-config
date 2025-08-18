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
  cfg = config.${namespace}.gaming.games.minecraft;
in
{
  options.${namespace}.gaming.games.minecraft = with types; {
    enable = mkBoolOpt false "Enable Minecraft";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prismlauncher
    ];
    
    #AFTER THIS OPTION IS SET, RUN PROTONUP
    environment.sessionVariables = {
   
    };

    
  };
} 