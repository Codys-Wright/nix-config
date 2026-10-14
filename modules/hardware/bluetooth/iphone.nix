# iPhone bridge (tether): BlueZ experimental (LE bearer for ANCS) + the
# A/V Hands-Free Class of Device, so the phone offers MAP / PBAP / ANCS / HFP.
# The user side (tetherd + Loft's Messages / notifications / calls) is
# programs.loft.phone.
{ ... }:
{
  fleet.hardware._.iphone = {
    description = "tether system side: BlueZ Experimental + A/V Hands-Free class on the first controller";
    nixos =
      { pkgs, ... }:
      {
        hardware.bluetooth.settings.General.Experimental = true;
        environment.systemPackages = [ pkgs.tether ];
        systemd.services."tether-btclass@hci0" = {
          description = "Set Bluetooth Class of Device to A/V Hands-Free for Tether";
          after = [ "bluetooth.service" ];
          partOf = [ "bluetooth.service" ];
          wantedBy = [ "bluetooth.service" ];
          path = [
            pkgs.bluez
            pkgs.coreutils
            pkgs.gnugrep
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutStartSec = 60;
          };
          script = ''
            for attempt in $(seq 30); do
              hci=hci0
              [ -e /sys/class/bluetooth/$hci ] || hci=$(ls /sys/class/bluetooth 2>/dev/null | head -n1)
              if [ -n "$hci" ]; then
                echo | btmgmt --index $hci class 4 8 >/dev/null 2>&1
                echo | btmgmt --index $hci info 2>/dev/null | grep -q "class 0x..0408" && exit 0
              fi
              sleep 1
            done
            exit 1
          '';
        };
      };
  };
}
