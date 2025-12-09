{ inputs, lib, den,
  FTS, ... }:

{
  FTS.kanata = {
    description = "Kanata keyboard remapper for both NixOS and Darwin";

    nixos = { config, pkgs, lib, ... }:
    {

      services.kanata = {
        enable = true;
        package = pkgs.kanata;
        keyboards.fts-kanata = {
          configFile = ./kanata.kbd;
          extraArgs = [ ];
          devices = [
            "/dev/input/by-path/pci-0000:0e:00.0-usb-0:5.1.1.2.1:1.0-event-kbd"  # Keychron K2 HE
            "/dev/input/by-path/pci-0000:0e:00.0-usb-0:5.2.4:1.2-event-kbd"       # Keychron Link
            "/dev/input/by-path/pci-0000:0e:00.0-usb-0:5.1.1.1.3:1.0-event-kbd"  # Logitech USB Receiver (keyboard 1)
            "/dev/input/by-path/pci-0000:0e:00.0-usb-0:5.2.2:1.2-event-kbd"      # Logitech USB Receiver (keyboard 2)
          ];
          port = null;
          extraDefCfg = "process-unmapped-keys yes";
        };
      };

      # Add the Kanata service user to necessary groups for input devices
      systemd.services.kanata-fts-kanata.serviceConfig = {
        SupplementaryGroups = [
          "input"
          "uinput"
        ];
      };
    };

    darwin = { config, pkgs, lib, ... }:
    {
      # Install Kanata package
      environment.systemPackages = [ pkgs.kanata ];

      # Create launchd service for Kanata on Darwin
      launchd.user.agents.kanata = {
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.kanata}/bin/kanata"
            "--cfg" "${./kanata.kbd}"
          ];

          RunAtLoad = true;
          KeepAlive = true;

          StandardOutPath = "/tmp/kanata.log";
          StandardErrorPath = "/tmp/kanata.log";
        };
      };

      # Grant necessary permissions for input access on macOS
      # Note: Users may need to grant Accessibility permissions manually
      # in System Preferences > Security & Privacy > Privacy > Accessibility
    };
  };
}
