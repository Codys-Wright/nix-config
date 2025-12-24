# Beacon display module - shows QR code and connection info on boot
# Based on nixos-images network-status
{
  FTS,
  lib,
  ...
}:
{
  FTS.deployment._.beacon-display = {
    description = ''
      Beacon display module that shows QR code and connection info on boot.

      Automatically generates a random password and displays it with IP addresses
      and a QR code for easy scanning.

      Usage:
        FTS.deployment._.beacon-display  # Include in beacon aspect
    '';

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        beacon-display = pkgs.writeShellScriptBin "beacon-display" ''
          # Get dynamically assigned IP addresses
          get_ips() {
            ${pkgs.iproute2}/bin/ip -brief addr | grep -v "127.0.0.1" | grep "UP" | ${pkgs.gawk}/bin/awk '{print $3}' | cut -d/ -f1
          }

          # Read password from shared location
          PASSWORD=$(cat /var/shared/installer-password 2>/dev/null || echo "generating...")
          HOSTNAME=$(${pkgs.nettools}/bin/hostname)
          IPS=$(get_ips | tr '\n' ' ')
          FIRST_IP=$(get_ips | head -1)

          # Generate QR code data
          QR_DATA="ssh installer@$FIRST_IP | password: $PASSWORD"

          # Clear screen
          clear

          # Display header
          echo "╔════════════════════════════════════════════════════════════════╗"
          echo "║                      NIXOS BEACON INSTALLER                    ║"
          echo "╚════════════════════════════════════════════════════════════════╝"
          echo ""

          # Display QR code if qrencode is available
          if command -v ${pkgs.qrencode}/bin/qrencode >/dev/null 2>&1; then
            echo "$QR_DATA" | ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8 -m 2
            echo ""
          fi

          # Display connection info
          echo "┌─ CONNECTION INFO ──────────────────────────────────────────────┐"
          echo "│ Hostname:  $HOSTNAME"
          echo "│ Password:  $PASSWORD"
          echo "│ IP(s):     $IPS"
          echo "└────────────────────────────────────────────────────────────────┘"
          echo ""
          echo "CONNECT:  ssh installer@$FIRST_IP"
          echo "          OR (if host key warning):"
          echo "          ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null installer@$FIRST_IP"
          echo ""
          echo "DISKS:    run 'show-disks' to see available disks"
          echo "INSTALL:  nix run .#HOSTNAME-install-on-beacon (from your laptop)"
          echo ""
        '';
      in
      {
        # Generate random password at boot
        system.activationScripts.installer-password = lib.stringAfter [ "users" ] ''
          mkdir -p /var/shared
          if [ ! -f /var/shared/installer-password ]; then
            ${pkgs.xkcdpass}/bin/xkcdpass --numwords 3 --delimiter - --count 1 > /var/shared/installer-password
            echo "installer:$(cat /var/shared/installer-password)" | ${pkgs.shadow}/bin/chpasswd
          fi
        '';

        # Add beacon-display to packages
        environment.systemPackages = [
          beacon-display
          pkgs.qrencode
        ];

        # Auto-run on tty1
        programs.bash.interactiveShellInit = lib.mkAfter ''
          if [[ "$(tty)" == "/dev/tty1" ]] && [[ -z "$BEACON_DISPLAYED" ]]; then
            export BEACON_DISPLAYED=1
            ${beacon-display}/bin/beacon-display
          fi
        '';
      };
  };
}
