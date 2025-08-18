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
  cfg = config.${namespace}.services.selfhost.calibre;
  library = "/var/lib/calibre-server";
in
{
  options.${namespace}.services.selfhost.calibre = with types; {
    enable = mkBoolOpt false "Enable calibre";
  };

  config = mkIf cfg.enable {
    fileSystems."/var/lib/calibre-server" = {
      device = "/mnt/data/nextcloud/data/ryan/files/Documents/calibre";
      options = [ "bind" ];
    };
    services = {
      calibre-server = {
        enable = true;

        host = "0.0.0.0";
        port = 8195;
        libraries = [ library ];
        auth.enable = false;

        user = "nextcloud";
        group = "nextcloud";
      };
      calibre-web = {
        enable = true;
        listen = {
          ip = "0.0.0.0";
          port = 8095;
        };
        options = {
          enableBookConversion = true;
          enableBookUploading = true;
          reverseProxyAuth.enable = true;
          calibreLibrary = "/var/lib/calibre-server";
        };

        user = "nextcloud";
        group = "nextcloud";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8195 ];
    systemd.services.calibre-web.after = [ "calibre-server.service" ];
  };
}
