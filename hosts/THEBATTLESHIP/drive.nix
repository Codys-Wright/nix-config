# Drive on THEBATTLESHIP: the production node (drive.fasttrackstudio.app,
# through the VPS's Caddy) and cody's agent with its mount at ~/Drive, both
# the release's Nix packages (modules/apps/misc/drive.nix) as user services.
# They replace the hand-started `systemd-run --user` units that ran the
# checkout's target/release binaries.
#
# The node keeps its data where it always was: `data/` in the Drive checkout
# on the Development drive (about 90 GB), and the web apps it serves are
# still those checkouts' dx builds. The agent keeps ~/.local/share/drive-agent.
#
# Dev builds never touch these: they run isolated (drive's scripts/dev.sh,
# their own --dir and port).
{ inputs, ... }:
let
  checkout = "/run/media/Development/fasttrackstudio";
in
{
  den.aspects."cody@THEBATTLESHIP".homeManager =
    { pkgs, ... }:
    let
      drive = inputs.drive.packages.${pkgs.stdenv.hostPlatform.system};
      apps = [
        "/=target/dx/drive-app/release/web/public"
        "/studio=${checkout}/studio/target/dx/studio-app/debug/web/public"
        "/season=${checkout}/season/target/dx/season/release/web/public"
        "/frame=${checkout}/frame-app/target/dx/frame-app/release/web/public"
      ];
    in
    {
      # drive-desktop: Drive in the tray, its window a click away (and in
      # the launcher, from its .desktop entry).
      home.packages = [
        drive.drive
        drive.drive-desktop
      ];

      # The tray icon for the session (`--background`: no window until
      # it is clicked). The app's own "Open at Login" would make a second
      # entry pointing into the store: leave it off.
      systemd.user.services.drive-desktop = {
        Unit = {
          Description = "Drive in the system tray";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${drive.drive-desktop}/bin/drive-desktop --background";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      systemd.user.services.drive-node = {
        Unit = {
          Description = "Drive node (drive.fasttrackstudio.app)";
          After = [ "network-online.target" ];
          # The data is on the Development drive.
          RequiresMountsFor = [ "${checkout}/drive" ];
        };
        Service = {
          WorkingDirectory = "${checkout}/drive";
          ExecStart = builtins.concatStringsSep " " (
            [
              "${drive.drive-node}/bin/drive-node"
              "--listen 127.0.0.1:8096"
              "--data data"
              "--org codywright"
              "--issuer https://auth.fasttrackstudio.app"
            ]
            ++ map (a: "--app ${a}") apps
          );
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };

      # The agent, serving ~/Drive. fusermount3 is the setuid wrapper. No
      # unmount before it starts: one started beside a running agent
      # (a switch while another is serving) would take that agent's mount
      # away.
      systemd.user.services.drive = {
        Unit = {
          Description = "Drive agent and its mount at ~/Drive";
          After = [ "drive-node.service" ];
        };
        Service = {
          Environment = [ "PATH=/run/wrappers/bin:${pkgs.fuse3}/bin:/run/current-system/sw/bin" ];
          ExecStart = "${drive.drive}/bin/drive mount %h/Drive";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
