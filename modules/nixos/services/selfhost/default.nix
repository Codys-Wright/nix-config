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
      dnsCredentialsFile = mkOpt path "" ''
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

    # SSL certificate management via ACME + Cloudflare
    security.acme = mkIf (cfg.baseDomain != "" && cfg.cloudflare.dnsCredentialsFile != "") {
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
        environmentFile = cfg.cloudflare.dnsCredentialsFile;
      };
    };

    # Caddy reverse proxy configuration
    services.caddy = mkIf (cfg.baseDomain != "") {
      enable = true;
      globalConfig = ''
        auto_https off
      '';
      virtualHosts = {
        # HTTP to HTTPS redirect for base domain
        "http://${cfg.baseDomain}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };
        # HTTP to HTTPS redirect for all subdomains
        "http://*.${cfg.baseDomain}" = {
          extraConfig = ''
            redir https://{host}{uri}
          '';
        };
      };
    };

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