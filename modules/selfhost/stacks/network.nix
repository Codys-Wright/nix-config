# Network stack: ProtonVPN + Samba client tools
{
  fleet,
  ...
}:
let
  inherit (import ../_data/vars.nix) domain;
in
{
  fleet.selfhost._.stack-network = {
    description = "Network stack: ProtonVPN with kill switch and Samba client tools";

    includes = [
      # ProtonVPN - VPN service with kill switch
      (fleet.selfhost._.protonvpn {
        inherit domain;
        usernameKey = "starcommand/selfhost/openvpn/username";
        passwordKey = "starcommand/selfhost/openvpn/password";
        remoteServerIP = "149.40.62.62";
        killswitch = {
          enable = true;
          allowedSubnets = [
            "192.168.0.0/16"
            "10.0.0.0/8"
          ];
          allowedIPs = [
            "192.168.0.114" # Synology NAS
          ];
          exemptPorts = [ 22 ];
        };
      })

      # Samba Client Tools - SMB/CIFS utilities for network shares
      (fleet.selfhost._.samba-client { })
    ];
  };
}
