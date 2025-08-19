
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
  cfg = config.${namespace}.app.misc.rustdesk-client;
in
{
  options.${namespace}.app.misc.rustdesk-client = with types; {
    enable = mkBoolOpt false "Enable the rustdesk client";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rustdesk-flutter
    ];
  };
}
