# Statime PTP daemon for Inferno / Dante clock sync.
#
# Parametric — each host supplies its Dante NIC and (optionally) the Dante
# device it wants locked as preferred PTP leader.
#
#   (fleet.music._.production._.statime {
#     interface  = "enp12s0";
#     # Optional: lock a specific device as Dante PTP leader
#     preferredLeader = "AA-4202524000109";
#   })
#
# The Dante interface lives on the host, so we take it as a parameter rather
# than trying to auto-detect it. The host's name is used for service
# descriptions so multiple hosts in a fleet can be told apart in journalctl.
{ fleet, lib, ... }:
{
  fleet.music._.production._.statime = {
    description = "Statime PTP daemon (Inferno fork) for Dante clock sync";

    __functor =
      _self:
      {
        interface,
        preferredLeader ? null,
        loglevel ? "warn",
        sdoId ? 0,
        domain ? 0,
        priority1 ? 251,
        protocolVersion ? "PTPv1",
        ...
      }:
      {
        includes = [
          (
            { host, ... }:
            {
              nixos =
                { pkgs, ... }:
                let
                  statimePkg = pkgs.callPackage ../../../packages/statime/statime.nix { };
                  netaudioPkg = pkgs.callPackage ../../../packages/netaudio/netaudio.nix { };
                  configPath = "/etc/inferno/statime-ptpv1.toml";
                in
                {
                  environment.systemPackages = [
                    statimePkg
                    netaudioPkg
                  ];

                  environment.etc."inferno/statime-ptpv1.toml".text = ''
                    loglevel = "${loglevel}"
                    sdo-id = ${toString sdoId}
                    domain = ${toString domain}
                    priority1 = ${toString priority1}
                    virtual-system-clock = true
                    virtual-system-clock-base = "monotonic_raw"
                    usrvclock-export = true

                    [[port]]
                    interface = "${interface}"
                    network-mode = "ipv4"
                    hardware-clock = "none"
                    protocol-version = "${protocolVersion}"
                  '';

                  systemd.services.statime-inferno = {
                    description = "Statime PTP daemon for ${host.name} Dante network";
                    after = [ "network-online.target" ];
                    wants = [ "network-online.target" ];
                    wantedBy = [ "multi-user.target" ];
                    serviceConfig = {
                      Type = "simple";
                      ExecStart = "${statimePkg}/bin/statime --config ${configPath}";
                      Restart = "on-failure";
                      RestartSec = "3s";
                    };
                  };
                }
                // lib.optionalAttrs (preferredLeader != null) {
                  systemd.services.dante-preferred-leader = {
                    description = "Lock ${preferredLeader} as Dante PTP preferred leader";
                    after = [ "statime-inferno.service" ];
                    wants = [ "statime-inferno.service" ];
                    wantedBy = [ "multi-user.target" ];
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                      ExecStart = "${netaudioPkg}/bin/netaudio --name ${preferredLeader} device config preferred-leader on";
                    };
                  };
                };
            }
          )
        ];
      };
  };
}
