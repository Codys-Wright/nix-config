
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
  cfg = config.${namespace}.services.rustdesk-server;
in
{
  options.${namespace}.services.rustdesk-server = with types; {
    enable = mkBoolOpt false "Enable the ruskdesk server";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
        rustdesk-server
    ];

  };
}
