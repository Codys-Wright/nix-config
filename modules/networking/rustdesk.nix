# RustDesk remote desktop, reached over Tailscale by IP ("direct IP access",
# TCP 21118, opened on tailscale0 only), so no relay server is involved.
# The service is RustDesk's own `--service` (it starts the per-session server
# in the logged-in user's session). The package is RustDesk's unattended
# Wayland build (packages/rustdesk-unattended-wayland): it captures through
# DRM/KMS, so there is no screen-share dialog, which also sidesteps RustDesk
# 1.4.x's PipeWire failure on niri (rustdesk#15916).
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
        rustdesk = pkgs.rustdesk-unattended-wayland;
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
          # ScreenCast + uinput (the fallback when DRM capture is unavailable).
          path = [
            "/run/wrappers"
            pkgs.procps
          ];
          environment = {
            # The server runs share/rustdesk/rustdesk directly, not bin/rustdesk.
            GST_PLUGIN_SYSTEM_PATH_1_0 = rustdesk.gstPluginPath;
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

        # The DRM capture library is dlopen()ed by this absolute path only (no
        # soname fallback); without it RustDesk silently drops to PipeWire.
        systemd.tmpfiles.rules = [
          "L+ /usr/lib/rustdesk/libdrmtap.so.0 - - - - ${rustdesk}/lib/rustdesk/libdrmtap.so.0"
        ];

        # Direct IP access only from the tailnet.
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 21118 ];
      };
  };
}
