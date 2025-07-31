{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.printing;
in
{
  options.${namespace}.services.printing = with types; {
    enable = mkBoolOpt false "Whether or not to configure printing support.";
  };

  config = mkIf cfg.enable {
    services = {
      avahi = {
        # Needed to find wireless printer
        enable = true;

        nssmdns4 = true;
        publish = {
          # Needed for detecting the scanner
          enable = true;

          addresses = true;
          userServices = true;
        };
      };
      printing = {
        enable = true;
        drivers = [ pkgs.cnijfilter2 ];
      };
    };
  };
}
