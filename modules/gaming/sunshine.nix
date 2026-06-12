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
    includes = [ (den.lib.groups [ "uinput" ]) ];

    nixos =
      { pkgs, lib, ... }:
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
          # Vendored 2026.516.143833 (security fix) until nixpkgs catches up —
          # see ../../packages/sunshine/package.nix and nixpkgs issue #524668.
          package = pkgs.callPackage ../../packages/sunshine/package.nix {
            cudaSupport = true;
            cudaPackages = pkgs.cudaPackages;
          };

          settings = {
            # Capture the AOC on HDMI-A-1 so a stream uses that dedicated
            # display instead of the main 3 monitors. The matching niri
            # window-rule (rules.kdl) lands Steam Big Picture on the same
            # output, so streaming never disturbs the main workspaces.
            #
            # NOTE: confirm this name against the output list Sunshine logs at
            # startup (and shows in the web UI) — the wlroots/KMS capture names
            # the output by its connector, which is "HDMI-A-1" here. If capture
            # comes up black or on the wrong screen, this is the value to fix.
            output_name = "HDMI-A-1";

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
          # So we must re-declare Sunshine's built-in defaults (Desktop, Low Res
          # Desktop) alongside our customized Steam Big Picture, or they vanish.
          applications = {
            env.PATH = "/run/current-system/sw/bin";
            apps = [
              {
                # Streams whatever is on the captured output (HDMI-A-1).
                name = "Desktop";
                image-path = "desktop.png";
              }
              {
                # Stock Sunshine uses `xrandr` here, which is X11-only and does
                # nothing on niri/Wayland. Drop the AOC to 1080p for the stream
                # and restore its native mode afterwards via niri.
                name = "Low Res Desktop";
                image-path = "desktop.png";
                prep-cmd = [
                  {
                    do = "${lib.getExe pkgs.niri} msg output HDMI-A-1 mode 1920x1080@60.000";
                    undo = "${lib.getExe pkgs.niri} msg output HDMI-A-1 mode 2560x1440@143.912";
                  }
                ];
              }
              {
                name = "Steam Big Picture";
                # Make sure the streaming display is awake before launch.
                prep-cmd = [
                  {
                    do = "${lib.getExe pkgs.niri} msg output HDMI-A-1 on";
                    undo = "";
                  }
                ];
                # Launch Big Picture INSIDE gamescope so Big Picture *and every
                # game launched from it* live in one nested surface (app-id
                # "gamescope"). The niri window-rule pins that single surface to
                # the HDMI "stream" workspace, fullscreen — so games launched
                # from Big Picture stay on the AOC instead of escaping to the
                # main "gaming" workspace. Desk gaming via the normal Steam
                # client is unaffected. -W/-H match the AOC; tune flags if
                # gamepad UI / input misbehaves.
                detached = [
                  "/run/current-system/sw/bin/gamescope -W 2560 -H 1440 -f --steam -- steam -gamepadui"
                ];
                image-path = "steam.png";
                # Tear it down when the stream ends.
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
