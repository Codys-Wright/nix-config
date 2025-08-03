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
  cfg = config.${namespace}.hardware.audio;
in
{
  options.${namespace}.hardware.audio = with types; {
    enable = mkBoolOpt false "Enable audio system";
  };

  config = mkIf cfg.enable {
    # Enable the modular audio components
    ${namespace} = {
      hardware.audio = {
        pipewire = enabled;
        wireguard = enabled;
      };
    };
  };
}
