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
  cfg = config.${namespace}.services.selfhost.utility.fail2ban-cloudflare;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.utility.fail2ban-cloudflare = with types; {
    enable = mkBoolOpt false "Enable fail2ban with Cloudflare integration";
    
    apiKeyFile = mkOpt str "" "File containing your Cloudflare API key, scoped to Firewall Rules: Edit";
    
    zoneId = mkOpt str "" "Cloudflare Zone ID";
    
    jails = mkOpt (attrsOf (submodule {
      options = {
        serviceName = mkOpt str "" "Name of the systemd service to monitor";
        failRegex = mkOpt str "" "Regex pattern to match failed login attempts";
        ignoreRegex = mkOpt str "" "Regex pattern to ignore certain log entries";
        maxRetry = mkOpt int 3 "Maximum number of failures before banning";
      };
    })) {} "Fail2ban jail configurations";
    
    homepage = {
      name = mkOpt str "Fail2Ban" "Name shown on homepage";
      description = mkOpt str "Intrusion prevention system with Cloudflare integration" "Description shown on homepage";
      icon = mkOpt str "fail2ban.svg" "Icon shown on homepage";
      category = mkOpt str "Utility" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      extraPackages = [
        pkgs.curl
        pkgs.jq
      ];

      jails = mapAttrs (name: value: {
        settings = {
          bantime = "30d";
          findtime = "1h";
          enabled = true;
          backend = "systemd";
          journalmatch = "_SYSTEMD_UNIT=${value.serviceName}.service";
          port = "http,https";
          filter = "${name}";
          maxretry = value.maxRetry;
          action = "cloudflare-token-agenix";
        };
      }) cfg.jails;
    };

    environment.etc = mergeAttrsList [
      (mapAttrs' (
        name: value:
        (nameValuePair ("fail2ban/filter.d/${name}.conf") ({
          text = ''
            [Definition]
            failregex = ${value.failRegex}
            ignoreregex = ${value.ignoreRegex}
          '';
        }))
      ) cfg.jails)
      {
        "fail2ban/action.d/cloudflare-token-agenix.conf".text =
          let
            notes = "Fail2Ban on ${config.networking.hostName}";
            cfapi = "https://api.cloudflare.com/client/v4/zones/${cfg.zoneId}/firewall/access_rules/rules";
          in
          ''
            [Definition]
            actionstart =
            actionstop =
            actioncheck =
            actionunban = id=$(curl -s -X GET "${cfapi}" \
                -H @${cfg.apiKeyFile} -H "Content-Type: application/json" \
                    | jq -r '.result[] | select(.notes == "${notes}" and .configuration.target == "ip" and .configuration.value == "<ip>") | .id')
                if [ -z "$id" ]; then echo "id for <ip> cannot be found"; exit 0; fi; \
                curl -s -X DELETE "${cfapi}/$id" \
                    -H @${cfg.apiKeyFile} -H "Content-Type: application/json" \
                    --data '{"cascade": "none"}'
            actionban = curl -X POST "${cfapi}" -H @${cfg.apiKeyFile} -H "Content-Type: application/json" --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'
            [Init]
            name = cloudflare-token-agenix
          '';
      }
    ];
  };
} 