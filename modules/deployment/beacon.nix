# Installation Beacon module
# Non-parametric aspect for bootable ISO/USB generation with hardcoded config
{
  inputs,
  den,
  lib,
  FTS,
  ...
}: {
  FTS.deployment._.beacon = {
    description = ''
      Installation beacon for bootable ISO/USB generation.

      Static configuration with hardcoded SSH keys for trusted machines.

      Authentication:
      - Password: Random 3-word password generated on boot (shown on screen)
      - SSH Keys: Hardcoded keys for THEBATTLESHIP, starcommand, and cody

      Usage:
        FTS.deployment._.beacon  # Include in beacon aspect
    '';

    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: let
      # Hardcoded configuration
      username = "installer";
      hostname = "nixos-beacon";

      # Hardcoded trusted SSH keys
      sshKeys = [
        # THEBATTLESHIP deploy key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGTCYWYifaiPcQVQnebV/cFVnvGULPJ2+jVEkPIEgXg THEBATTLESHIP-deploy"
        # starcommand deploy key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBJxxU1TXbV1IvGFm67X7jX+C7uRtLcgimcoDGxapNP starcommand-deploy"
        # cody personal key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO8y8AMfYQnvu3BvjJ54/qYJcedNkMHmnjexine1ypda cody@THEBATTLESHIP"
      ];

      helptext = ''
        Run 'beacon-display' to see connection info with QR code
        Run 'show-disks' to see available disks
      '';
    in {
      # Use the hardcoded hostname
      networking.hostName = lib.mkDefault hostname;

      # Allow root to connect for nixos-anywhere
      users.users.root = {
        openssh.authorizedKeys.keys = sshKeys;
      };

      # Create the installer user
      users.users.${username} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
        ];
        # Allow login without password (password generated on boot)
        initialHashedPassword = "";
        openssh.authorizedKeys.keys = sshKeys;
      };

      # Auto-login at virtual consoles
      services.getty.autologinUser = lib.mkForce username;
      nix.settings.trusted-users = [username];
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Auto-run beacon-help on login
      programs.bash.interactiveShellInit = ''
        # Only run on first login (tty1)
        if [[ "$(tty)" == "/dev/tty1" ]] && [[ -z "$BEACON_HELP_SHOWN" ]]; then
          export BEACON_HELP_SHOWN=1
          beacon-help
        fi
      '';

      # Configure ISO image (NixOS 25.05+ options)
      image.fileName = lib.mkForce "beacon.iso";
      image.baseName = lib.mkForce "beacon";

      networking.firewall.allowedTCPPorts = [22];

      boot.loader.systemd-boot.enable = true;

      environment.systemPackages = let
        beacon-help = pkgs.writeText "beacon-help" helptext;
        show-disks = pkgs.writeShellScriptBin "show-disks" ''
          echo "=== AVAILABLE DISKS ==="
          ${pkgs.util-linux}/bin/lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -v loop
        '';
      in [
        (pkgs.writeShellScriptBin "beacon-help" ''
          cat ${beacon-help}
          echo ""
          ${show-disks}/bin/show-disks
        '')
        show-disks
        pkgs.nixos-facter
        pkgs.tmux
        # Network tools
        pkgs.dig
        # System tools
        pkgs.htop
        pkgs.glances
        pkgs.iotop
      ];

      # Use DHCP by default - actualIp is just a placeholder
      # Real IP will be detected dynamically by beacon-display
      networking.useDHCP = lib.mkDefault true;

      # Getty help text
      services.getty.helpLine = lib.mkForce ''

        === NIXOS BEACON ===
        Hostname: ${hostname}
        Run 'beacon-display' to see connection info with QR code
        WARNING: Installation will ERASE all connected disks!
      '';
    };
  };
}
