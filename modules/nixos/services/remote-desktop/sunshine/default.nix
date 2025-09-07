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
  cfg = config.${namespace}.services.remote-desktop.sunshine;
in
{
  options.${namespace}.services.remote-desktop.sunshine = with types; {
    enable = mkBoolOpt false "Enable Sunshine (Game streaming host)";
  };

  config = mkIf cfg.enable {
    # Use the native NixOS Sunshine service with sensible defaults
    services.sunshine = {
      enable = true;
      openFirewall = true;
      autoStart = true;
      capSysAdmin = true;
    };
  };
}
