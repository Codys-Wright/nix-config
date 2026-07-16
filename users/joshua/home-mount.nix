# Joshua's home directory bind mount with execution hardening.
{ ... }:
{
  den.aspects.joshua-home-mount = {
    description = "Joshua's /home bind mount from /persist with noexec/nodev/nosuid hardening";

    nixos =
      { ... }:
      {
        # Keep Joshua's writable home on a separate bind mount with noexec/nodev/nosuid
        # so downloaded AppImages and other portable binaries cannot be executed from
        # his home directory.
        fileSystems."/home/joshua" = {
          device = "/persist/home/joshua";
          fsType = "none";
          options = [
            "bind"
            "noexec"
            "nodev"
            "nosuid"
            "x-systemd.requires-mounts-for=/persist"
          ];
        };

        systemd.services."persist-home-joshua-init" = {
          description = "Create /persist/home/joshua before the /home/joshua bind mount";
          # Start this from persist.mount, not home-joshua.mount, to avoid a
          # boot-order cycle with local-fs.target and nix-daemon.socket.
          wantedBy = [ "persist.mount" ];
          before = [ "home-joshua.mount" ];
          after = [ "persist.mount" ];
          # DefaultDependencies pulls in After=sysinit.target, which closes a
          # boot-order cycle: sysinit.target -> persist-home-joshua-init ->
          # home-joshua.mount -> local-fs.target -> systemd-binfmt -> sysinit.
          # systemd breaks the cycle by deleting a job at random, sometimes the
          # one feeding the display manager (boots to a bare "_"). This service
          # only needs /persist mounted, so drop the default ordering.
          unitConfig = {
            RequiresMountsFor = "/persist";
            DefaultDependencies = false;
          };
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /persist/home/joshua
            chown joshua:users /persist/home/joshua
            chmod 0700 /persist/home/joshua
          '';
        };
      };
  };
}
