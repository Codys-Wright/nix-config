# Deployment packages flake module
# Generates per-host packages for deployment operations
# Similar to skarabox's flakeModule
{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      # Get all hosts for this system from the flake
      nixosConfigs = inputs.self.nixosConfigurations or { };

      # Generate packages for a single host
      mkHostPackages =
        hostname: hostConfig:
        let
          # Check if host has deployment config
          tryGetCfg = builtins.tryEval (hostConfig.config.deployment or { });
          deploymentCfg = if tryGetCfg.success then tryGetCfg.value else { };
          hasDeployment = (deploymentCfg.enable or false) && (deploymentCfg.ip or "") != "";

          # Get beacon ISO if available
          hasISO = hostConfig.config.system.build ? isoImage;

          # Only generate packages for hosts with deployment enabled
        in
        lib.optionalAttrs hasDeployment (
          {
            # Install on beacon using nixos-anywhere
            "${hostname}-install-on-beacon" = pkgs.writeShellApplication {
              name = "${hostname}-install-on-beacon";
              runtimeInputs = with pkgs; [
                nixos-anywhere
                openssh
              ];
              text = ''
                echo "Installing NixOS on ${hostname} via beacon..."
                echo "Target IP: ${deploymentCfg.ip or "not configured"}"
                echo "SSH Port: ${toString (deploymentCfg.sshPort or 22)}"
                echo ""

                nixos-anywhere \
                  --flake ".#${hostname}" \
                  --ssh-port ${toString (deploymentCfg.sshPort or 22)} \
                  ${deploymentCfg.sshUser or "root"}@${deploymentCfg.ip or ""}
              '';
            };

            # SSH into the host
            "${hostname}-ssh" = pkgs.writeShellApplication {
              name = "${hostname}-ssh";
              runtimeInputs = with pkgs; [ openssh ];
              text = ''
                ssh -p ${toString (deploymentCfg.sshPort or 22)} \
                    ${deploymentCfg.sshUser or "root"}@${deploymentCfg.ip or ""}
              '';
            };

            # Get hardware facts from host
            "${hostname}-get-facter" = pkgs.writeShellApplication {
              name = "${hostname}-get-facter";
              runtimeInputs = with pkgs; [ openssh ];
              text = ''
                echo "Collecting hardware facts from ${hostname}..."
                ssh -p ${toString (deploymentCfg.sshPort or 22)} \
                    ${deploymentCfg.sshUser or "root"}@${deploymentCfg.ip or ""} \
                    "nixos-facter"
              '';
            };

            # Generate known_hosts file
            "${hostname}-gen-knownhosts-file" = pkgs.writeShellApplication {
              name = "${hostname}-gen-knownhosts-file";
              runtimeInputs = with pkgs; [ openssh ];
              text = ''
                echo "Generating known_hosts for ${hostname}..."
                ssh-keyscan -p ${toString (deploymentCfg.sshPort or 22)} \
                            ${deploymentCfg.ip or ""} > ./hosts/${hostname}/known_hosts
                echo "Saved to ./hosts/${hostname}/known_hosts"
              '';
            };
          }
          // lib.optionalAttrs hasISO {
            # Build beacon ISO (only for hosts with ISO config)
            "${hostname}-beacon" = hostConfig.config.system.build.isoImage;

            # Run beacon in QEMU VM for testing
            "${hostname}-vm" = pkgs.writeShellApplication {
              name = "${hostname}-vm";
              runtimeInputs = with pkgs; [ qemu_kvm ];
              text = ''
                set -euo pipefail

                # Parse arguments - GUI is default, use --no-gui to disable
                GUI_MODE=true
                HOST_PORT=2222
                BOOT_PORT=2223

                for arg in "$@"; do
                  case "$arg" in
                    --no-gui) GUI_MODE=false ;;
                    *)
                      # If it's a number, treat as HOST_PORT (first positional arg)
                      if [[ "$arg" =~ ^[0-9]+$ ]]; then
                        if [ "$HOST_PORT" = "2222" ]; then
                          HOST_PORT="$arg"
                        elif [ "$BOOT_PORT" = "2223" ]; then
                          BOOT_PORT="$arg"
                        fi
                      fi
                      ;;
                  esac
                done

                # Setup VM directory and disk images
                VM_DIR=".${hostname}-vm-tmp"
                mkdir -p "$VM_DIR"

                # Create disk images if they don't exist (silently)
                if [ ! -f "$VM_DIR/disk1.qcow2" ]; then
                  ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 "$VM_DIR/disk1.qcow2" 40G >/dev/null 2>&1
                fi

                if [ ! -f "$VM_DIR/disk2.qcow2" ]; then
                  ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 "$VM_DIR/disk2.qcow2" 20G >/dev/null 2>&1
                fi

                # Build ISO path
                ISO_PATH="${hostConfig.config.system.build.isoImage}/iso/beacon.iso"

                # Single line output
                echo "Starting ${hostname} VM | SSH: localhost:$HOST_PORT | Connect: ssh -p $HOST_PORT installer@localhost"

                # QEMU display args
                if [ "$GUI_MODE" = "true" ]; then
                  DISPLAY_ARGS=( -display gtk )
                else
                  DISPLAY_ARGS=( -nographic )
                fi

                # Run QEMU
                exec ${pkgs.qemu_kvm}/bin/qemu-kvm \
                  -name "${hostname}-test-vm" \
                  -m 2048 \
                  -smp 2 \
                  -cpu host \
                  -machine q35 \
                  -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
                  "''${DISPLAY_ARGS[@]}" \
                  -cdrom "$ISO_PATH" \
                  -boot order=d \
                  -drive file="$VM_DIR/disk1.qcow2",if=virtio,format=qcow2 \
                  -drive file="$VM_DIR/disk2.qcow2",if=virtio,format=qcow2 \
                  -nic user,hostfwd=tcp::"$HOST_PORT"-:22,hostfwd=tcp::"$BOOT_PORT"-:2222 \
                  -virtfs local,path=/nix/store,mount_tag=store,security_model=none,readonly=on
              '';
            };
          }
        );

      # Generate packages for all hosts (filter by system)
      allHostPackages = lib.foldl' (
        acc: hostname:
        let
          hostConfig = nixosConfigs.${hostname};
          # Only generate packages for hosts matching this system
          hostSystem = hostConfig.pkgs.stdenv.hostPlatform.system or null;
        in
        if hostSystem == system then acc // (mkHostPackages hostname hostConfig) else acc
      ) { } (builtins.attrNames nixosConfigs);

    in
    {
      packages = allHostPackages // {
        # USB imager utility (if needed)
        beacon-usbimager = pkgs.writeShellApplication {
          name = "beacon-usbimager";
          runtimeInputs = with pkgs; [ usbimager ];
          text = ''
            echo "Starting USB Imager..."
            echo "1. Select ISO file in row 1"
            echo "2. Select USB device in row 3"
            echo "3. Click write (arrow down) in row 2"
            usbimager
          '';
        };

        # SSH into beacon VM (ignores host key warnings)
        beacon-ssh = pkgs.writeShellApplication {
          name = "beacon-ssh";
          runtimeInputs = with pkgs; [ openssh ];
          text = ''
            # Default beacon VM SSH port
            PORT="''${1:-2222}"
            echo "Connecting to beacon on port $PORT (ignoring host key check)..."
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$PORT" installer@localhost
          '';
        };
      };
    };
}
