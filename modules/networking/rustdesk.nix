# RustDesk remote desktop, reached over Tailscale by IP ("direct IP access",
# TCP 21118, opened on tailscale0 only), so no relay server is involved.
# The service is RustDesk's own `--service` (it starts the per-session server
# in the logged-in user's session). On Wayland (niri) each incoming session
# needs the screen-share portal approved at the machine; for unattended
# access use Sunshine + Moonlight (<fleet.gaming/sunshine>).
#
# One-time, per host (not in nix: the password is a secret):
#   sudo rustdesk --option direct-server Y
#   sudo rustdesk --password '…'
#
#   <fleet.networking/rustdesk>
{ ... }:
{
  fleet.networking._.rustdesk = {
    description = "RustDesk remote desktop: service + direct IP access over Tailscale";

    nixos =
      { pkgs, ... }:
      let
        rustdesk = pkgs.rustdesk-flutter;
      in
      {
        environment.systemPackages = [ rustdesk ];

        # Mirrors upstream's rustdesk.service.
        systemd.services.rustdesk = {
          description = "RustDesk";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "systemd-user-sessions.service"
            "display-manager.service"
          ];
          # It starts the per-session `rustdesk --server` with `sudo -u <user>`
          # from PATH: the setuid wrapper. The server inherits this PATH and
          # detects the service with `ps aux | grep rustdesk` (scrap's
          # is_server_running): without procps it falls back to the
          # RemoteDesktop portal, which niri's portal (gnome) doesn't have
          # ("Wayland requires higher version of linux distro"); with it,
          # ScreenCast + uinput, and the share choice persists (restore token).
          path = [
            "/run/wrappers"
            pkgs.procps
          ];
          environment = {
            PULSE_LATENCY_MSEC = "60";
            PIPEWIRE_LATENCY = "1024/48000";
          };
          serviceConfig = {
            ExecStart = "${rustdesk}/bin/rustdesk --service";
            Restart = "always";
            RestartSec = 2;
            KillMode = "mixed";
            TimeoutStopSec = 30;
            LimitNOFILE = 100000;
          };
        };

        # Direct IP access only from the tailnet.
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 21118 ];
      };
  };
}
