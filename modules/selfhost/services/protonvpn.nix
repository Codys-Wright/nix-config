# ProtonVPN Service
# VPN service using ProtonVPN with OpenVPN
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.protonvpn =
    {
      domain,
      # VPN configuration
      dev ? "tun0",
      routingNumber ? 10,
      # Required secrets
      usernameKey,
      passwordKey,
      # Kill switch configuration
      killswitch ? {
        enable = true;
        allowedSubnets = [
          "192.168.0.0/16"
          "10.0.0.0/8"
        ];
        exemptPorts = [ 22 ];
      },
      # Optional proxy
      proxyPort ? null,
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        ProtonVPN - VPN service using ProtonVPN with OpenVPN.

        Features:
        - OpenVPN with ProtonVPN servers
        - Kill switch to block traffic if VPN disconnects
        - Automatic failover across multiple servers
        - Optional HTTP proxy for routing traffic through VPN

        Configuration:
        - Device: ${dev}
        - Kill switch: ${if killswitch.enable then "enabled" else "disabled"}
        ${if proxyPort != null then "- Proxy port: ${toString proxyPort}" else ""}
      '';

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          # Create auth file from username and password secrets
          authFilePath = "/run/openvpn/protonvpn-auth";
        in
        {
          # ProtonVPN OpenVPN configuration
          shb.vpn.protonvpn = {
            enable = true;
            provider = "protonvpn";
            inherit dev routingNumber;
            
            # Auth file will be created by systemd ExecStartPre
            authFile = authFilePath;
            
            # Kill switch configuration
            inherit killswitch;
            
            # Optional proxy
            inherit proxyPort;
          };

          # Create auth file before OpenVPN starts
          systemd.services.openvpn-protonvpn = {
            preStart = ''
              mkdir -p /run/openvpn
              echo "$(cat ${config.shb.sops.secret."${usernameKey}".result.path})" > ${authFilePath}
              echo "$(cat ${config.shb.sops.secret."${passwordKey}".result.path})" >> ${authFilePath}
              chmod 600 ${authFilePath}
            '';
          };

          # SOPS secrets - these will be wired in the parent module (selfhost.nix)
          # We just need to reference them here
        };
    };
}
