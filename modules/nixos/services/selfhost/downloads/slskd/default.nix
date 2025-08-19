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
  cfg = config.${namespace}.services.selfhost.downloads.slskd;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.downloads.slskd = with types; {
    enable = mkBoolOpt false "Enable SLSKD (Soulseek client)";
    
    configDir = mkOpt str "/var/lib/slskd" "Configuration directory for SLSKD";
    
    musicDir = mkOpt str "${selfhostCfg.mounts.fast}/Media/Music/Library" "Directory for music library";
    
    downloadDir = mkOpt str "${selfhostCfg.mounts.fast}/Media/Music/Import" "Directory for downloads";
    
    incompleteDownloadDir = mkOpt str "${selfhostCfg.mounts.fast}/Media/Music/Import.tmp" "Directory for incomplete downloads";
    
    url = mkOpt str "slskd.${selfhostCfg.baseDomain}" "URL for SLSKD service";
    
    environmentFile = mkOpt path "" "Environment file with SLSKD credentials (USERNAME, PASSWORD, JWT)";
    
    homepage = {
      name = mkOpt str "SLSKD" "Name shown on homepage";
      description = mkOpt str "Soulseek client" "Description shown on homepage";
      icon = mkOpt str "slskd.svg" "Icon shown on homepage";
      category = mkOpt str "Downloads" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Note: SLSKD service configuration would need to be implemented
    # This is a placeholder for the complex SLSKD setup from the original
    # The original has extensive Docker container configuration
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:5030
      '';
    };
    
    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.musicDir} 0755 ${selfhostCfg.user} ${selfhostCfg.group} - -"
      "d ${cfg.downloadDir} 0755 ${selfhostCfg.user} ${selfhostCfg.group} - -"
      "d ${cfg.incompleteDownloadDir} 0755 ${selfhostCfg.user} ${selfhostCfg.group} - -"
    ];
    
    # TODO: Implement full SLSKD container configuration
    # The original uses complex Docker setup with beets integration
  };
} 