# 10G network interface tuning with jumbo frames and TCP buffer optimization
{
  fleet,
  lib,
  ...
}:
{
  fleet.system._.network-10g = {
    description = "10G network tuning: jumbo frames, TCP buffers, NFS client";

    __functor =
      _self:
      {
        interface ? "enp12s0",
        ...
      }:
      {
        nixos =
          { pkgs, ... }:
          {
            # Jumbo frames via NetworkManager
            networking.networkmanager.ensureProfiles.profiles."10g-jumbo" = {
              connection = {
                id = "10G Jumbo";
                type = "ethernet";
                interface-name = interface;
                autoconnect = "true";
              };
              ethernet.mtu = 9000;
              ipv4.method = "auto";
              ipv6.method = "auto";
            };

            # TCP buffer tuning for 10G throughput
            boot.kernel.sysctl = {
              "net.core.rmem_max" = 16777216;
              "net.core.wmem_max" = 16777216;
              "net.core.rmem_default" = 1048576;
              "net.core.wmem_default" = 1048576;
              "net.ipv4.tcp_rmem" = "4096 1048576 16777216";
              "net.ipv4.tcp_wmem" = "4096 1048576 16777216";
              "net.core.netdev_max_backlog" = 5000;
            };

            # NFS client support
            environment.systemPackages = [ pkgs.nfs-utils ];
          };
      };
  };
}
