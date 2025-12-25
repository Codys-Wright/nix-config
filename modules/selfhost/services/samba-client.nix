# Samba Client Tools
# Provides SMB/CIFS client utilities for network file sharing
{
  FTS,
  inputs,
  lib,
  ...
}:
{
  FTS.selfhost._.samba-client =
    {
      enable ? true,
      packages ? null,
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      description = ''
        Samba Client Tools - SMB/CIFS client utilities for network file sharing.

        Provides:
        - smbclient: Command-line SMB client
        - mount.cifs: CIFS filesystem mount utility
        - nmblookup: NetBIOS name lookup
        - Various SMB utilities

        Used for connecting to Windows shares, NAS devices, and other SMB servers.
      '';

      nixos = {
        config,
        lib,
        pkgs,
        ...
      }: {
        # Samba client packages
        environment.systemPackages = with pkgs; [
          samba
          cifs-utils
        ];

        # Firewall rules for SMB discovery (NetBIOS name service)
        networking.firewall.extraCommands = ''
          iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns || true
        '';

        # Allow SMB ports through firewall
        networking.firewall.allowedTCPPorts = [
          445  # SMB over TCP
        ];
        networking.firewall.allowedUDPPorts = [
          137  # NetBIOS name service
          138  # NetBIOS datagram service
        ];
      };
    };
}