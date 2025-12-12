# Installation Beacon module
# Parametric aspect for bootable ISO/USB generation with smart defaults
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.deployment._.beacon = {
    description = ''
      Installation beacon for bootable ISO/USB generation.
      
      Automatically derives settings from deployment.config when possible.
      
      Usage:
        FTS.deployment._.beacon  # Uses all defaults from deployment.config
        (<FTS.deployment/beacon> { ip = "192.168.1.50"; })  # Override IP
    '';

    __functor =
      _self:
      {
        ip ? null,  # Defaults to deployment.staticNetwork.ip or "192.168.50.1"
        username ? null,  # Defaults to deployment.username
        sshAuthorizedKey ? null,  # Defaults to deployment.sshKey
        hostname ? null,  # Defaults to config.networking.hostName or "beacon"
        enableHotspot ? true,
        ...
      }@args:
      { class, aspect-chain }:
      let
        readAndTrim = f: lib.strings.trim (builtins.readFile f);
        readAsStr = v: if lib.isPath v then readAndTrim v else v;
      in
      {
        # Hotspot will be automatically configured by deployment.hotspot if enabled
        # Set deployment.hotspot.enable = true in config to enable
        includes = [];

        nixos = { config, pkgs, lib, ... }:
        let
          cfg = config.deployment;
          
          # Smart defaults from deployment.config
          actualIp = if ip != null then ip
                    else if cfg.staticNetwork != null then cfg.staticNetwork.ip
                    else "192.168.50.1";
          
          actualUsername = if username != null then username else cfg.username;
          
          actualSshKey = if sshAuthorizedKey != null then readAsStr sshAuthorizedKey
                        else if cfg.sshKey != null then cfg.sshKey
                        else throw "beacon: no SSH key available (set deployment.sshKey or provide sshAuthorizedKey)";
          
          actualHostname = if hostname != null then hostname 
                          else "${config.networking.hostName}-beacon";
          
          helptext = ''
            * Step 1.  Enable network access to this server.

            For a wired network connection, just plug in an ethernet cable from your router
            to this server. The connection will be made automatically.

            For a wireless connection, if a card is found, a "NixOS-Hotspot" wifi hotspot will
            be created automatically. Connect to it from your laptop.

            The IP address for this beacon is ${actualIp}.

            * Step 2.  Identify the disk layout.

            To know what disk existing in the system, type the command "lsblk" without
            the double quotes. This will show lines like so:

            NAME             TYPE
            /dev/nvme0n1     disk             This is an NVMe drive
            /dev/sda         disk             This is an SSD or HDD drive
            /dev/sdb         disk             This is an SSD or HDD drive

            With the above setup, configure your deployment settings accordingly.

            * Step 3.  Run the installer.

            From your laptop, run the installer. The server will then reboot automatically
            in the new system as soon as the installer ran successfully.

            Enjoy your NixOS system!
          '';
        in
        {
          # Use the derived hostname
          networking.hostName = lib.mkDefault actualHostname;

          # Allow root to connect for nixos-anywhere
          users.users.root = {
            openssh.authorizedKeys.keys = [ actualSshKey ];
          };

          # Create the admin user
          users.users.${actualUsername} = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" "video" ];
            # Allow graphical login without password
            initialHashedPassword = "";
            openssh.authorizedKeys.keys = [ actualSshKey ];
          };

          # Auto-login at virtual consoles
          services.getty.autologinUser = lib.mkForce actualUsername;
          nix.settings.trusted-users = [ actualUsername ];
          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          # Configure ISO image
          isoImage.isoName = lib.mkForce "beacon.iso";
          isoImage.isoBaseName = lib.mkForce "beacon";

          networking.firewall.allowedTCPPorts = [ 22 ];

          boot.loader.systemd-boot.enable = true;

          environment.systemPackages = 
            let
              beacon-help = pkgs.writeText "beacon-help" helptext;
            in
            [
              (pkgs.writeShellScriptBin "beacon-help" ''
                cat ${beacon-help}
              '')
              pkgs.nixos-facter
              pkgs.tmux
              # Network tools
              pkgs.dig
              # System tools
              pkgs.htop
              pkgs.glances
              pkgs.iotop
            ];

          # Static IP for wired connection
          systemd.network = {
            enable = true;
            networks."10-lan" = {
              matchConfig.Name = "en*";
              address = [ "${actualIp}/24" ];
              linkConfig.RequiredForOnline = true;
            };
          };

          # Getty help text
          services.getty.helpLine = lib.mkForce ''

            /           \
           |/  _.-=-._  \|       NIXOS BEACON
           \'_/`-. .-'\_'/
            '-\ _ V _ /-'
              .' 'v' '.     Hello, you just booted on the NixOS installation beacon.
            .'|   |   |'.   Congratulations!
            v'|   |   |'v
              |   |   |     Nothing is installed yet on this server. To abort, just
             .\   |   /.    shutdown this server and remove the USB stick.
            (_.'._^_.'._)
             \\       //    To complete the installation of NixOS on this server, you
              \'-   -'/     must follow the steps below to run the installer.




           WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING
           *                                                                           *
           *    Running the installer WILL ERASE EVERYTHING on this server.            *
           *    Make sure the only drives connected and powered on are the disks to    *
           *    install the Operating System on. This drive should be a SSD or NVMe    *
           *    drive for optimal performance.                                         *
           *                                                                           *
           *                       THESE DRIVES WILL BE ERASED.                        *
           *                                                                           *
           WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING



          Run the command `beacon-help` to print more details.

          The IP address for this beacon is ${actualIp}.
          The hostname for this beacon is ${actualHostname}.
        '';
        };
      };
  };
}
