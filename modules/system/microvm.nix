# MicroVM aspect — spin up any host config as a local VM for testing
#
# Usage:
#   den.hosts.x86_64-linux.my-test = {
#     users.cody = {};
#     aspect = "my-test";
#   };
#   den.aspects.my-test = {
#     includes = [
#       (fleet.microvm { graphics = true; })
#       <fleet.desktop/environment/niri>
#       (fleet.coding { shell = { default = "fish"; }; })
#     ];
#   };
#
# Run with: nix run .#my-test
{
  inputs,
  fleet,
  den,
  lib,
  ...
}:
{
  fleet.system._.microvm = {
    description = "MicroVM for local testing — wraps any host config as a QEMU VM";

    __functor =
      _self:
      {
        mem ? 4096,
        vcpu ? 4,
        graphics ? true,
        sshPort ? 2222,
        ...
      }:
      {
        includes = [
          # Auto-login the first user via greetd
          (
            { host, ... }:
            let
              firstUser = lib.head (builtins.attrNames host.users);
            in
            {
              nixos =
                { pkgs, ... }:
                {
                  # Writable tmpfs home for each user
                  fileSystems = lib.listToAttrs (
                    map (u: {
                      name = "/home/${u}";
                      value = {
                        device = "tmpfs";
                        fsType = "tmpfs";
                        options = [
                          "size=512M"
                          "mode=0755"
                        ];
                      };
                    }) (builtins.attrNames host.users)
                  );

                  # Simple passwords for VM access (no SOPS)
                  users.users = lib.mapAttrs (name: _: {
                    initialPassword = name;
                  }) host.users;

                  # Auto-login first user
                  services.greetd = lib.mkIf graphics {
                    enable = true;
                    settings.default_session = {
                      command = if builtins.hasAttr "niri" pkgs then "${pkgs.niri}/bin/niri-session" else "bash";
                      user = firstUser;
                    };
                  };
                };
            }
          )
        ];

        nixos =
          { pkgs, ... }:
          {
            imports = [ inputs.microvm.nixosModules.microvm ];

            microvm = {
              hypervisor = "qemu";
              inherit mem vcpu;
              shares = [
                {
                  proto = "9p";
                  tag = "ro-store";
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                }
              ];
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
                  host.port = sshPort;
                  guest.port = 22;
                }
              ];
              graphics.enable = graphics;
            };

            # Nix daemon + temproots for home-manager activation
            nix.enable = true;
            systemd.tmpfiles.rules = [ "d /nix/var/nix/temproots 1777 root root -" ];

            # SSH access for debugging
            users.users.root.initialPassword = "root";
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = true;
              };
            };
            networking.firewall.allowedTCPPorts = [ 22 ];
          };
      };
  };
}
