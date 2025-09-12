{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.samba;
in
{
  options.${namespace}.services.samba = with types; {
    enable = mkBoolOpt false "Enable Samba file sharing service";
    shares = mkOption {
      type = attrsOf (submodule {
        options = {
          path = mkOpt str "" "Path to the shared directory";
          browseable = mkOpt str "yes" "Whether the share is browseable";
          writable = mkOpt str "yes" "Whether the share is writable";
          "read only" = mkOpt str "no" "Whether the share is read-only";
          "guest ok" = mkOpt str "no" "Whether guest access is allowed";
          "create mask" = mkOpt str "0644" "Create mask for new files";
          "directory mask" = mkOpt str "0755" "Create mask for new directories";
          "valid users" = mkOpt str "cody" "Valid users for this share";
          "follow symlinks" = mkOpt str "yes" "Whether to follow symbolic links";
          "wide links" = mkOpt str "yes" "Whether to allow wide links";
          comment = mkOpt str "" "Share description";
        };
      });
      default = {};
      description = "Samba shares configuration";
    };
    workgroup = mkOpt str "WORKGROUP" "Samba workgroup";
    security = mkOpt str "user" "Samba security mode";
    extraGlobalConfig = mkOption {
      type = attrsOf str;
      default = {};
      description = "Additional global Samba configuration";
    };
  };

  config = mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = mkMerge [
        {
          global = mkMerge [
            {
              workgroup = cfg.workgroup;
              "server string" = config.networking.hostName;
              "netbios name" = config.networking.hostName;
              security = cfg.security;
              "invalid users" = [ "root" ];
              "guest account" = "nobody";
              "map to guest" = "bad user";
              "passdb backend" = "tdbsam";
              "preserve case" = "yes";
              "short preserve case" = "yes";
              "fruit:aapl" = "yes";
              "vfs objects" = "catia fruit streams_xattr";
              "allow insecure wide links" = "yes";
              "unix extensions" = "no";
            }
            cfg.extraGlobalConfig
          ];
        }
        (mapAttrs (name: shareCfg: {
          inherit (shareCfg) path browseable writable comment;
          "read only" = shareCfg."read only";
          "guest ok" = shareCfg."guest ok";
          "create mask" = shareCfg."create mask";
          "directory mask" = shareCfg."directory mask";
          "valid users" = shareCfg."valid users";
          "follow symlinks" = shareCfg."follow symlinks";
          "wide links" = shareCfg."wide links";
        }) cfg.shares)
      ];
    };

    # Enable Avahi for service discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
      };
    };

    # Enable WS-Discovery for Windows clients
    services.samba-wsdd.enable = true;

    # Ensure Samba user exists
    users.users.samba = {
      isSystemUser = true;
      group = "samba";
      description = "Samba service user";
    };

    users.groups.samba = {};

    environment.systemPackages = with pkgs; [
      samba
      cifs-utils
    ];

    # Create Samba password for the main user
    system.activationScripts.sambaSetup = ''
      # Create Samba password for cody user
      if ! ${pkgs.samba}/bin/pdbedit -L | grep -q "^cody:"; then
        echo -e "password\npassword\n" | ${pkgs.samba}/bin/smbpasswd -a cody -s
      fi
    '';
  };
}
