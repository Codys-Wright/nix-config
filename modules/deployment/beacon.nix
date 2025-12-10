# Installation Beacon module
# Creates a bootable ISO/USB for installing NixOS on remote servers
{
  inputs,
  den,
  lib,
  deployment,
  ...
}:
let
  inherit (lib) mkForce types;
  readAndTrim = f: lib.strings.trim (builtins.readFile f);
  readAsStr = v: if lib.isPath v then readAndTrim v else v;
in
{
  deployment.beacon = {
    description = "Installation beacon for bootable ISO/USB generation";
    
    # Include hotspot aspect for WiFi access
    includes = [ deployment.hotspot ];

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) mkForce types;
      cfg = config.deployment.beacon;
      # Access hostname from config (set by den) or use default
      hostname = config.networking.hostName or cfg.hostname;

      helptext = ''
        * Step 1.  Enable network access to this server.

        For a wired network connection, just plug in an ethernet cable from your router
        to this server. The connection will be made automatically.

        For a wireless connection, if a card is found, a "NixOS-Hotspot" wifi hotspot will
        be created automatically. Connect to it from your laptop.

        The IP address for this beacon is ${cfg.ip}.

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
      options.deployment.beacon = {
        enable = lib.mkEnableOption "installation beacon";

        ip = lib.mkOption {
          description = "Static IP for beacon";
          type = types.str;
        };

        hostname = lib.mkOption {
          description = "Hostname to give the beacon. Defaults to config.networking.hostName if set by den";
          type = types.str;
          default = "beacon";
        };

        username = lib.mkOption {
          description = "Username with which you can log on the beacon. Use the same as for the host to simplify installation";
          type = types.str;
          default = "admin";
        };

        sshAuthorizedKey = lib.mkOption {
          type = with types; oneOf [ str path ];
          description = "Public key to connect to the beacon. Use the same as for the host to simplify installation";
          apply = readAsStr;
        };
      };

      config = lib.mkIf cfg.enable {
        # Use hostname from config if available (set by den), otherwise use cfg.hostname
        networking.hostName = lib.mkDefault hostname;

        # Also allow root to connect for nixos-anywhere
        users.users.root = {
          openssh.authorizedKeys.keys = [ cfg.sshAuthorizedKey ];
        };

        # Override user set in profiles/installation-device.nix
        users.users.${cfg.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" "networkmanager" "video" ];
          # Allow the graphical user to login without password
          initialHashedPassword = "";
          # Set shared ssh key
          openssh.authorizedKeys.keys = [ cfg.sshAuthorizedKey ];
        };

        # Automatically log in at the virtual consoles
        services.getty.autologinUser = lib.mkForce cfg.username;
        nix.settings.trusted-users = [ cfg.username ];
        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        # Configure ISO image name
        isoImage.isoName = mkForce "beacon.iso";
        isoImage.isoBaseName = mkForce "beacon";

        networking.firewall.allowedTCPPorts = [ 22 ];

        boot.loader.systemd-boot.enable = true;

        environment.systemPackages = let
          beacon-help = pkgs.writeText "beacon-help" helptext;
        in [
          (pkgs.writeShellScriptBin "beacon-help" ''
            cat ${beacon-help}
          '')
          pkgs.nixos-facter
          pkgs.tmux
          # Useful network tools
          pkgs.dig
          # Useful system tools
          pkgs.htop
          pkgs.glances
          pkgs.iotop
        ];

        systemd.network = {
          enable = true;
          networks."10-lan" = {
            matchConfig.Name = "en*";
            address = [
              "${cfg.ip}/24"
            ];
            linkConfig.RequiredForOnline = true;
          };
        };

        # Configure hotspot to use the same IP
        deployment.hotspot = {
          enable = true;
          ip = cfg.ip;
        };

        services.getty.helpLine = mkForce ''

          /           \\
         |/  _.-=-._  \\|       NIXOS BEACON
         \\'_/`-. .-'\\_'/
          '-\\ _ V _ /-'
            .' 'v' '.     Hello, you just booted on the NixOS installation beacon.
          .'|   |   |'.   Congratulations!
          v'|   |   |'v
            |   |   |     Nothing is installed yet on this server. To abort, just
           .\\   |   /.    shutdown this server and remove the USB stick.
          (_.'._^_.'._)
           \\\\       //    To complete the installation of NixOS on this server, you
            \\'-   -'/     must follow the steps below to run the installer.




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

        The IP address for this beacon is ${cfg.ip}.
        The hostname for this beacon is ${hostname}.
      '';
      };
    };
  };
}

