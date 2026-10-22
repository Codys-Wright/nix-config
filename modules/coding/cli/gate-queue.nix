# gate-queue for an agent account (STA-402): durable, lease-aware build gates that
# wake their Paperclip issue when they finish.
#
#   (<fleet.coding.cli/gate-queue> { user = "agent"; })
#
# - `gate-queue` (daemon + CLI) and `gate-submit` (symlink) on the system path.
# - A systemd *user* unit `gate-queue.service` (wantedBy default.target, so it
#   starts with the user manager, which has Linger). The unit is global to the
#   user manager, so ConditionUser pins it to `user`; every other account skips it.
# - KillMode=process: restarting or stopping the daemon never touches a running
#   gate (gates run as transient `gate-*.service` units from `systemd-run --user`);
#   the daemon re-adopts them on start.
#
# Source and macOS LaunchAgent (airlock has no nix-darwin yet, so that one is a
# manual placement): modules/coding/cli/gate-queue/, docs/gate-queue.md.
{ ... }:
{
  fleet.coding._.cli._.gate-queue.__functor =
    _self:
    {
      user,
      home ? "/home/${user}",
      ...
    }:
    {
      name = "gate-queue(${user})";
      description = "Durable lease-aware build gates that wake their Paperclip issue, for ${user}";
      nixos =
        { lib, pkgs, ... }:
        let
          gate-queue =
            pkgs.runCommand "gate-queue"
              {
                nativeBuildInputs = [ pkgs.python3 ];
                meta.mainProgram = "gate-queue";
              }
              ''
                install -Dm755 ${./gate-queue/gate-queue} $out/bin/gate-queue
                patchShebangs $out/bin/gate-queue
                # gate-submit is the same program; it dispatches on argv[0]
                ln -s gate-queue $out/bin/gate-submit
              '';
        in
        {
          environment.systemPackages = [ gate-queue ];
          systemd.user.services.gate-queue = {
            description = "gate-queue: lease-aware build gates that wake their Paperclip issue";
            wantedBy = [ "default.target" ];
            unitConfig.ConditionUser = user;
            # ${home}/.local/bin carries the hand-placed build-lease and pc.
            environment = {
              PATH = lib.mkForce (
                lib.concatStringsSep ":" [
                  "${home}/.local/bin"
                  "/etc/profiles/per-user/${user}/bin"
                  "/run/current-system/sw/bin"
                  "/run/wrappers/bin"
                  "/nix/var/nix/profiles/default/bin"
                ]
              );
              PYTHONUNBUFFERED = "1";
            };
            serviceConfig = {
              ExecStart = "${gate-queue}/bin/gate-queue daemon";
              Restart = "always";
              RestartSec = 5;
              KillMode = "process";
            };
          };
        };
    };
}
