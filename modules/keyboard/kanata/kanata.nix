{
  fleet.kanata = {
    description = "Kanata keyboard remapper for both NixOS and Darwin";

    nixos =
      { lib, ... }:
      {
        # Enable uinput hardware support.
        # This loads the kernel module and sets up the necessary udev rule.
        hardware.uinput.enable = true;

        services.kanata = {
          enable = true;
          keyboards.default = {
            devices = [
              "/dev/input/by-id/usb-Keychron_Keychron_K2_HE-event-kbd"
              "/dev/input/by-id/usb-Keychron_Keychron_Link-if02-event-kbd"
            ];
            configFile = ./kanata.kbd;
          };
        };

        # Steam's udev uaccess rule adds an ACL on /dev/uinput that zeroes the
        # POSIX group entry, breaking DynamicUser group-based access.
        # Run as root instead to bypass the permission issue entirely.
        systemd.services.kanata-default.serviceConfig.DynamicUser = lib.mkForce false;
      };

    darwin =
      { pkgs, ... }:
      {
        # Install Kanata package
        environment.systemPackages = [ pkgs.kanata ];

        # Create launchd service for Kanata on Darwin
        launchd.user.agents.kanata = {
          serviceConfig = {
            ProgramArguments = [
              "${pkgs.kanata}/bin/kanata"
              "--cfg"
              "${./kanata.kbd}"
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
