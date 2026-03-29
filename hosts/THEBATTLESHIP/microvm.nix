# MicroVM configuration for THEBATTLESHIP
# Lightweight NixOS VM for local testing — no SOPS, no hardware deps
# Run with: nix run .#THEBATTLESHIP-vm
{
  inputs,
  FTS,
  __findFile,
  ...
}:
{
  den.hosts.x86_64-linux.THEBATTLESHIP-vm = {
    description = "THEBATTLESHIP MicroVM — lightweight local test environment";
    aspect = "THEBATTLESHIP-vm";
    # No users — avoids SOPS/home-manager setup in VM
  };

  den.aspects.THEBATTLESHIP-vm = {
    description = "MicroVM for local THEBATTLESHIP testing (qemu, ephemeral, SSH on port 2222)";
    includes = [
      <FTS.coding/cli>
      <FTS.coding/editors>
      <FTS.coding/shells>
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        imports = [ inputs.microvm.nixosModules.microvm ];

        microvm = {
          hypervisor = "qemu";
          mem = 2048;
          vcpu = 2;
          shares = [
            {
              # Share the host /nix/store read-only for fast startup
              proto = "9p";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          # User-mode networking with SSH port forwarding (host:2222 → guest:22)
          interfaces = [
            {
              type = "user";
              id = "vm-eth0";
              mac = "02:00:00:00:00:01";
            }
          ];
          forwardPorts = [
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
          ];
        };

        networking.hostName = "THEBATTLESHIP-vm";
        time.timeZone = "America/Los_Angeles";

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "yes";
            PasswordAuthentication = true;
          };
        };
        networking.firewall.allowedTCPPorts = [ 22 ];

        # Root password for easy local access
        users.users.root.initialPassword = "root";

        environment.systemPackages = with pkgs; [
          git
          htop
          just
        ];

      };
  };
}
