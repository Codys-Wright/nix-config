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
  cfg = config.${namespace}.gaming.proton;
in
{
  options.${namespace}.gaming.proton = with types; {
    enable = mkBoolOpt false "Enable Proton compatibility tools";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      protonup
    ];
    
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    
  };
} 