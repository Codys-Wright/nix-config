# WiFi Hotspot module
# Creates a WiFi hotspot for easy access to the system
{
  inputs,
  den,
  lib,
  deployment,
  ...
}:
{
  deployment.hotspot = {
    description = "WiFi hotspot configuration for easy system access";

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) mkOption types;
      cfg = config.deployment.hotspot;
      hotspotService = "deployment-hotspot-createap";
    in
    {
      options.deployment.hotspot = {
        enable = lib.mkEnableOption "WiFi hotspot";

        ip = mkOption {
          description = "IP address of the system in the hotspot network";
          type = types.str;
          default = "192.168.12.1";
        };

        ssid = mkOption {
          description = "SSID (network name) for the hotspot";
          type = types.str;
          default = "NixOS-Hotspot";
        };
      };

      config = lib.mkIf cfg.enable {
        # Ensure linux-wifi-hotspot is available
        environment.systemPackages = [ pkgs.linux-wifi-hotspot ];

        systemd.services."${hotspotService}@" = {
          description = "Create AP Service";
          after = [ "network.target" "network-pre.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.linux-wifi-hotspot}/bin/create_ap --redirect-to-localhost -n -g ${cfg.ip} %I ${cfg.ssid}";
            KillSignal = "SIGINT";
            Restart = "on-failure";
          };
        };

        systemd.services."deployment-hotspot-force-udev" = {
          description = "Trigger udev for existing wlan interfaces";
          after = [ "systemd-udev-settle.service" "network-pre.target" ];
          before = [ "network.target" ];
          wantedBy = [ "network.target" ];

          unitConfig = {
            DefaultDependencies = false;
          };

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemdMinimal}/bin/udevadm trigger --subsystem-match=net --property-match=DEVTYPE=wlan";
          };
        };

        # 'change' is needed to be correctly triggered by the udevadm trigger command.
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="net", ENV{DEVTYPE}=="wlan", TAG+="systemd", ENV{SYSTEMD_WANTS}="${hotspotService}@%k.service"
          ACTION=="remove",     SUBSYSTEM=="net", ENV{DEVTYPE}=="wlan", RUN+="${pkgs.systemdMinimal}/bin/systemctl stop ${hotspotService}@%k.service"
        '';
      };
    };
  };
}

