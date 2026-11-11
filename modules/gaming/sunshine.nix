# Sunshine - self-hosted game streaming host (Moonlight client compatible).
# Usage: <fleet.gaming/sunshine>
#
# Pair from a Moonlight client by adding the host manually at <host-ip>:47989,
# then enter the PIN shown in the Sunshine web UI at https://localhost:47990.
{
  fleet,
  den,
  __findFile,
  ...
}:
{
  fleet.gaming._.sunshine = {
    description = "Sunshine game-streaming host (NVENC, Moonlight-compatible)";

    # Virtual mouse/keyboard/gamepad injection goes through /dev/uinput.
    # Grant every host user access so any of them can stream input.
    includes = [ (fleet.user._.groups [ "uinput" ]) ];

    nixos =
      { pkgs, lib, ... }:
      let
        # Steam is single-instance per user. If the desktop Steam client is
        # already running, `steam` inside gamescope just hands off to it and
        # exits, gamescope has nothing to host, and Sunshine falls back to
        # streaming the bare desktop. So from Moonlight, shut the desktop
        # client down first and wait for it to exit before starting Big Picture.
        steam-stream = pkgs.writeShellScript "steam-stream" ''
          uid="$(${pkgs.coreutils}/bin/id -u)"
          if ${pkgs.procps}/bin/pgrep -u "$uid" -x steam >/dev/null 2>&1; then
            steam -shutdown >/dev/null 2>&1 || true
            for _ in $(seq 1 60); do
              ${pkgs.procps}/bin/pgrep -u "$uid" -x steam >/dev/null 2>&1 || break
              sleep 0.5
            done
          fi
          exec ${pkgs.gamescope}/bin/gamescope -W 2560 -H 1440 -f --steam -- steam -gamepadui
        '';
      in
      {
        # Moonlight client, so this host can also stream FROM other
        # Sunshine/GameStream hosts (not just serve via Sunshine below).
        environment.systemPackages = [ pkgs.moonlight-qt ];

        # uinput kernel module + udev rule for the virtual input devices.
        # (Also enabled by kanata; harmless to assert here so sunshine is
        # self-contained if kanata is ever dropped.)
        hardware.uinput.enable = true;

        services.sunshine = {
          enable = true;
          autoStart = true; # start with the user session
          capSysAdmin = true; # wrapper grants CAP_SYS_ADMIN for KMS capture
          openFirewall = true; # opens 47984-47990 TCP + 47998-48000/8000-8010 UDP

          # NVENC hardware encode on the RTX card. cudaSupport compiles
          # sunshine from source against cudatoolkit — the first build is long.
          package = pkgs.sunshine.override {
            cudaSupport = true;
            cudaPackages = pkgs.cudaPackages;
          };

          settings = {
            # Capture from DP-3 (right monitor, now landscape 16:9).
            # Streaming happens via virtual gamescope sessions (see apps below).
            output_name = "DP-3";

            # 2026 added CSRF protection: the web UI rejects any origin other
            # than localhost unless whitelisted here (comma-separated full
            # origins, no wildcards). Allow phone/remote access via the LAN IP,
            # the Tailscale IP, and the mDNS hostname. NOTE: the LAN IP is DHCP
            # and may change — the hostname/Tailscale entries are stable; update
            # the IP here (or set a DHCP reservation) if it moves.
            csrf_allowed_origins = builtins.concatStringsSep "," [
              "https://192.168.1.126:47990"
              "https://100.68.255.30:47990"
              "https://thebattleship:47990"
              "https://thebattleship.local:47990"
            ];
          };

          # Declaring applications here makes the app list fully declarative —
          # the web UI can no longer add/edit apps (settings still editable).
          applications = {
            env.PATH = "/run/current-system/sw/bin";
            apps = [
              {
                # Stream the main desktop as-is.
                name = "Desktop";
                image-path = "desktop.png";
              }
              {
                # Virtual 1440p gamescope session — independent of physical
                # displays. Launches gamescope in 2560x1440 16:9 resolution
                # ready for any application.
                name = "Gamescope 1440p";
                image-path = "steam.png";
                detached = [
                  "/run/current-system/sw/bin/gamescope -W 2560 -H 1440 -f -- bash"
                ];
                auto-detach = "true";
              }
              {
                # Stream Steam Big Picture in a virtual 1440p gamescope.
                name = "Steam Big Picture 1440p";
                image-path = "steam.png";
                detached = [ "${steam-stream}" ];
                auto-detach = "true";
              }
            ];
          };
        };

        # avahi/mDNS publishing (for Moonlight auto-discovery) is already
        # enabled host-wide via <fleet.system/avahi> with userServices = true.
      };
  };
}
