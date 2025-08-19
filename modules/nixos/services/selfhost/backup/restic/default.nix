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
  cfg = config.${namespace}.services.selfhost.backup.restic;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.backup.restic = with types; {
    enable = mkBoolOpt false "Enable Restic backup service";
    
    configDir = mkOpt str "/var/backup" "Directory for backup metadata";
    
    passwordFile = mkOpt path "" "File containing restic repository password";
    
    s3 = {
      enable = mkBoolOpt false "Enable S3 backups";
      url = mkOpt str "" "S3-compatible endpoint URL";
      environmentFile = mkOpt path "" "File containing S3 credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION)";
    };
    
    local = {
      enable = mkBoolOpt false "Enable local backups";
      targetDir = mkOpt str "${selfhostCfg.mounts.merged}/Backups/Restic" "Local backup target directory";
    };
    
    paperless = {
      enable = mkBoolOpt false "Enable paperless document backups";
    };
  };

  config = mkIf cfg.enable {
    # Create backup directories
    systemd.tmpfiles.rules = optional cfg.local.enable [
      "d ${cfg.local.targetDir} 0770 ${selfhostCfg.user} ${selfhostCfg.group} - -"
    ];
    
    # Database backups
    services.postgresqlBackup = mkIf config.services.postgresql.enable {
      enable = true;
      databases = config.services.postgresql.ensureDatabases;
    };
    
    services.mysqlBackup = mkIf config.services.mysql.enable {
      enable = true;
      databases = config.services.mysql.ensureDatabases;
    };
    
    # Restic configuration
    users.users.restic.createHome = mkForce false;
    
    systemd.services.restic-rest-server.serviceConfig = optionalAttrs cfg.local.enable {
      User = mkForce selfhostCfg.user;
      Group = mkForce selfhostCfg.group;
    };
    
    services.restic = {
      # Local restic server
      server = optionalAttrs cfg.local.enable {
        enable = true;
        dataDir = cfg.local.targetDir;
        extraFlags = [ "--no-auth" ];
      };
      
      backups = 
        # Local backups
        optionalAttrs cfg.local.enable {
          appdata-local = {
            timerConfig = {
              OnCalendar = "Mon..Sat *-*-* 05:00:00";
              Persistent = true;
            };
            repository = "rest:http://localhost:8000/appdata-local-${config.networking.hostName}";
            initialize = true;
            passwordFile = cfg.passwordFile;
            pruneOpts = [ "--keep-last 5" ];
            paths = [ "/tmp/appdata-local-${config.networking.hostName}.tar" ];
            backupPrepareCommand = 
              let
                restic = "${pkgs.restic}/bin/restic -r 'rest:http://localhost:8000/appdata-local-${config.networking.hostName}' -p ${cfg.passwordFile}";
              in
              ''
                ${restic} stats || ${restic} init
                ${restic} forget --prune --no-cache --keep-last 5
                # TODO: Auto-discover service config directories
                ${pkgs.gnutar}/bin/tar -cf /tmp/appdata-local-${config.networking.hostName}.tar ${selfhostCfg.mounts.config}
                ${restic} unlock
              '';
          };
        }
        # S3 backups
        // optionalAttrs cfg.s3.enable {
          appdata-s3 = {
            timerConfig = {
              OnCalendar = "Sun *-*-* 05:00:00";
              Persistent = true;
            };
            environmentFile = cfg.s3.environmentFile;
            repository = "s3:${cfg.s3.url}/appdata-${config.networking.hostName}";
            initialize = true;
            passwordFile = cfg.passwordFile;
            pruneOpts = [ "--keep-last 3" ];
            paths = [ "/tmp/appdata-s3-${config.networking.hostName}.tar" ];
            backupPrepareCommand = 
              let
                restic = "${pkgs.restic}/bin/restic -r 's3:${cfg.s3.url}/appdata-${config.networking.hostName}'";
              in
              ''
                ${restic} stats || ${restic} init
                ${restic} forget --prune --no-cache --keep-last 3
                ${pkgs.gnutar}/bin/tar -cf /tmp/appdata-s3-${config.networking.hostName}.tar ${selfhostCfg.mounts.config}
                ${restic} unlock
              '';
          };
        };
    };
  };
} 