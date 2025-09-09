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
  cfg = config.${namespace}.services.selfhost.networking.local-hosts;
  selfhostCfg = config.${namespace}.services.selfhost;

  # Use configured domains or extract from local Caddy if available
  domainNames = if cfg.domains != [] then cfg.domains else (
    let
      caddyHosts = lib.attrNames config.services.caddy.virtualHosts;
    in
    map (host:
      if lib.hasPrefix "http://" host then lib.removePrefix "http://" host
      else if lib.hasPrefix "https://" host then lib.removePrefix "https://" host
      else host
    ) caddyHosts
  );

  # Generate /etc/hosts entries for local access
  hostsEntries = map (domain: "${cfg.targetIP}    ${domain}") domainNames;
in
{
  options.${namespace}.services.selfhost.networking.local-hosts = with types; {
    enable = mkBoolOpt false "Enable local /etc/hosts entries for selfhost services";
    
    targetIP = mkOpt str "192.168.1.46" "IP address to point all selfhost domains to";
    
    domains = mkOpt (listOf str) [] "List of domains to add to /etc/hosts (if empty, will extract from local Caddy config)";
    
    referenceSystem = mkOpt (nullOr str) null "Reference another system's configuration to extract domains from";
    
    homepage = {
      name = mkOpt str "Local Hosts" "Name shown on homepage";
      description = mkOpt str "Local DNS resolution for selfhost services" "Description shown on homepage";
      icon = mkOpt str "dns.svg" "Icon shown on homepage";
      category = mkOpt str "Networking" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Add all Caddy virtual hosts to /etc/hosts pointing to target IP
    networking.hosts = {
      "${cfg.targetIP}" = domainNames;
    };

    # Optional: Create a script to generate hosts file entries
    environment.systemPackages = [
      (pkgs.writeScriptBin "generate-selfhost-hosts" ''
        #!${pkgs.bash}/bin/bash
        echo "# Selfhost services - generated on $(date)"
        echo "# Add these entries to your /etc/hosts file:"
        echo ""
        ${concatStringsSep "\n" (map (entry: "echo \"${entry}\"") hostsEntries)}
        echo ""
        echo "# Copy the above lines to your /etc/hosts file"
      '')
    ];
  };
}
