
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
  cfg = config.${namespace}.services.selfhost.networking.rustdesk-server;
in
{
  options.${namespace}.services.selfhost.networking.rustdesk-server = with types; {
    enable = mkBoolOpt false "Enable the ruskdesk server";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
        rustdesk-server
    ];

    services.rustdesk-server = {
        enable = true;
        openFirewall = true;
    };

  };
}
