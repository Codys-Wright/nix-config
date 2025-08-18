{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.selfhost.stirling-pdf;
in
{
  options.${namespace}.services.selfhost.stirling-pdf = with types; {
    enable = mkBoolOpt false "Enable stirling-pdf";
  };

  # disabledModules = [ "services/web-apps/stirling-pdf.nix" ];
  # imports = [ "${inputs.unstable}/nixos/modules/services/web-apps/stirling-pdf.nix" ];

  config = mkIf cfg.enable {
    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_PORT = 8001;
      };
    };
  };
}
