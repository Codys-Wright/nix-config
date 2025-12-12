# WiFi Hotspot module
# Creates a WiFi access point for bootstrap scenarios
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.deployment._.hotspot = {
    description = ''
      WiFi hotspot for bootstrap scenarios.
      
      Automatically uses deployment.staticNetwork.ip if configured.
    '';

    nixos = { config, pkgs, lib, ... }:
    let
      cfg = config.deployment;
      # Use static IP from deployment.config if set, otherwise use default
      hotspotIp = if cfg.staticNetwork != null then cfg.staticNetwork.ip else "192.168.50.1";
    in
    {
      options.deployment.hotspot = {
        enable = lib.mkEnableOption "WiFi hotspot" // { default = false; };
        ssid = lib.mkOption {
          type = lib.types.str;
          default = "NixOS-Hotspot";
        };
        passphrase = lib.mkOption {
          type = lib.types.str;
          default = "nixos-hotspot";
        };
      };

      config = lib.mkIf (cfg.enable && cfg.hotspot.enable) {
        environment.systemPackages = [ pkgs.linux-wifi-hotspot ];

        # Simple hotspot service using linux-wifi-hotspot
        systemd.services."deployment-hotspot@" = {
          description = "WiFi Hotspot Service";
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.linux-wifi-hotspot}/bin/create_ap --redirect-to-localhost -n -g ${hotspotIp} %I ${cfg.hotspot.ssid} ${cfg.hotspot.passphrase}";
            KillSignal = "SIGINT";
            Restart = "on-failure";
          };
        };

        # Auto-start hotspot on WiFi interfaces
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="net", ENV{DEVTYPE}=="wlan", TAG+="systemd", ENV{SYSTEMD_WANTS}="deployment-hotspot@%k.service"
        '';
      };
    };
  };
}
