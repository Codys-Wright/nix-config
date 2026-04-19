# Statime fork for Inferno/Dante clock sync
# Runs as a system service so PTP privileged ports and clock access work reliably
{ fleet, ... }:
{
  fleet.music._.production._.statime = {
    description = "Statime Inferno fork configured for Dante/PTPv1 on THEBATTLESHIP's 10G Dante NIC";

    nixos =
      { pkgs, ... }:
      let
        statimePkg = pkgs.callPackage ../../../packages/statime/statime.nix { };
      in
      {
        environment.systemPackages = [ statimePkg ];

        environment.etc."inferno/statime-ptpv1.toml".text = ''
          loglevel = "warn"
          sdo-id = 0
          domain = 0
          priority1 = 251
          virtual-system-clock = true
          virtual-system-clock-base = "monotonic_raw"
          usrvclock-export = true

          [[port]]
          # Verified via netaudio discovery: Dante devices are visible on the
          # 10G link enp12s0 (10.10.10.10), not on enp11s0.
          interface = "enp12s0"
          network-mode = "ipv4"
          hardware-clock = "none"
          protocol-version = "PTPv1"
        '';

        systemd.services.statime-inferno = {
          description = "Statime Inferno PTP daemon";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${statimePkg}/bin/statime --config /etc/inferno/statime-ptpv1.toml";
            Restart = "on-failure";
            RestartSec = "3s";
          };
        };
      };
  };
}
