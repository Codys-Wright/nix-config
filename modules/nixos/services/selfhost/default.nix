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
  cfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost = with types; {
    enable = mkBoolOpt false "Enable selfhost services and infrastructure";
    
    # Domain configuration
    baseDomain = mkOpt str "" ''
      Base domain name to be used to access the selfhost services via Caddy reverse proxy.
      Example: "yourdomain.com" will create services at "servicename.yourdomain.com"
    '';
    
    # Cloudflare integration for SSL certificates
    cloudflare = {
      dnsCredentialsFile = mkOpt (nullOr path) null ''
        Path to file containing Cloudflare DNS API credentials for ACME SSL certificates.
        File should contain: CF_DNS_API_TOKEN=your_token_here
      '';
    };
    
    # ACME SSL configuration
    acme = {
      email = mkOpt str "" "Email address for ACME SSL certificate registration";
    };
    
    # Mount paths for services
    mounts = {
      slow = mkOpt path "/mnt/storage" ''
        Path to the 'slow' tier storage mount for bulk data
      '';
      fast = mkOpt path "/mnt/cache" ''
        Path to the 'fast' tier storage mount for frequently accessed data
      '';
      config = mkOpt path "/persist/opt/services" ''
        Path to store service configuration files
      '';
      merged = mkOpt path "/mnt/user" ''
        Path to the merged storage mount
      '';
    };
    
    # User and group configuration
    user = mkOpt str "selfhost" ''
      User to run the selfhost services as
    '';
    group = mkOpt str "selfhost" ''
      Group to run the selfhost services as
    '';
    
    # Timezone configuration
    timeZone = mkOpt str "UTC" ''
      Time zone to be used for the selfhost services
    '';
    
    # Network access configuration
    networkAccess = {
      enable = mkBoolOpt false "Enable access from local network (not just localhost)";
      allowedNetworks = mkOpt (listOf str) [ "192.168.0.0/16" "10.0.0.0/8" "172.16.0.0/12" ] "Allowed network ranges for local access";
    };
  };



  config = mkIf cfg.enable {
    # Create selfhost user and group
    users = {
      groups.${cfg.group} = {
        gid = 993;
      };
      users.${cfg.user} = {
        uid = 994;
        isSystemUser = true;
        group = cfg.group;
      };
    };

    # Firewall configuration for web services
    networking.firewall.allowedTCPPorts = [
      80   # HTTP
      443  # HTTPS
    ];





    # SSL certificate management via ACME + Cloudflare using SOPS secrets
    security.acme = mkIf (cfg.baseDomain != "" && cfg.acme.email != "") {
      acceptTerms = true;
      defaults.email = cfg.acme.email;
      certs.${cfg.baseDomain} = {
        reloadServices = [ "caddy.service" ];
        domain = cfg.baseDomain;
        extraDomainNames = [ "*.${cfg.baseDomain}" ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        dnsPropagationCheck = true;
        group = config.services.caddy.group;
        environmentFile = "/run/secrets/cloudflare-credentials";
      };
    };

    # Create Cloudflare credentials file from SOPS secrets
    systemd.services.create-cloudflare-credentials = mkIf (cfg.baseDomain != "" && cfg.acme.email != "") {
      description = "Create Cloudflare credentials file from SOPS secrets";
      wantedBy = [ "multi-user.target" ];
      before = [ "acme-${cfg.baseDomain}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-cloudflare-credentials" ''
          cat > /run/secrets/cloudflare-credentials << EOF
          CLOUDFLARE_DNS_API_TOKEN=$(cat ${config.sops.secrets."cloudflare/api_token".path})
          CLOUDFLARE_ZONE_ID=$(cat ${config.sops.secrets."cloudflare/zone_id".path})
          EOF
          chmod 600 /run/secrets/cloudflare-credentials
        '';
      };
    };

    # Caddy reverse proxy configuration
    services.caddy = mkIf (cfg.baseDomain != "") {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      globalConfig = mkIf (cfg.acme.email == "") ''
        auto_https off
      '';
      # Individual services will add their own virtualHosts
    };

    # Automatically add all configured Caddy virtual hosts to /etc/hosts for local access
    networking.hosts = mkIf (cfg.baseDomain != "") (
      let
        # Extract all virtual hosts from Caddy configuration
        caddyHosts = lib.attrNames config.services.caddy.virtualHosts;
        # Filter out any protocol prefixes and get clean domain names
        domainNames = map (host: 
          if lib.hasPrefix "http://" host then lib.removePrefix "http://" host
          else if lib.hasPrefix "https://" host then lib.removePrefix "https://" host
          else host
        ) caddyHosts;
      in
      {
        "127.0.0.1" = domainNames;
      }
    );

    # Container infrastructure
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      autoPrune.enable = true;
      extraPackages = [ pkgs.zfs ];
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    virtualisation.oci-containers = {
      backend = "podman";
    };

    # Allow DNS queries on podman interface
    networking.firewall.interfaces.podman0.allowedUDPPorts =
      lib.lists.optionals config.virtualisation.podman.enable [ 53 ];

    # Required for some services
    nixpkgs.config.permittedInsecurePackages = [
      "dotnet-sdk-6.0.428"
      "aspnetcore-runtime-6.0.36"
    ];
  };
} 