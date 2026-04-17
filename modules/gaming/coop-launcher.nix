{ fleet, ... }:
{
  fleet.gaming._.coop-launcher = {
    description = "steam-as wrapper — launches another local user's Steam inside a nested gamescope compositor with SDL filters set so only their assigned virtual InputPlumber pad is visible. Every game launched from that Steam inherits the filter, so there's nothing to configure per-game.";

    nixos =
      { pkgs, ... }:
      {
        # Hide the InputPlumber virtual xbox-series pad (045e:0b12) AND the
        # raw pads it feeds from (DualSense 054c:0ce6 + its Edge 054c:0df2
        # + Xbox Wireless 045e:0b13, 0x0b20 + Xbox One 045e:02ea + Xbox
        # Elite 2 045e:0b00) from every user's Steam by default. `steam-as`
        # unsets this and sets _EXCEPT instead, so only the target user's
        # gamescoped Steam sees the virtual pad.
        #
        # New logins / newly-launched Steams inherit these values. A
        # currently-running Steam needs a full tray-quit + relaunch before
        # it picks up the env — in-memory processes don't re-read env.
        environment.sessionVariables.SDL_GAMECONTROLLER_IGNORE_DEVICES = "0x045e/0x0b12,0x054c/0x0ce6,0x054c/0x0df2,0x045e/0x0b13,0x045e/0x0b20,0x045e/0x02ea,0x045e/0x0b00";

        # Allow wheel users to setfacl on input device nodes without a
        # password — needed by steam-as to ACL-block other users from the
        # target pad. Steam's own controller enumeration (Steam Input API)
        # bypasses SDL_GAMECONTROLLER_IGNORE_DEVICES, so we have to block
        # at kernel level to keep cody's Steam from seeing bri's pad.
        security.sudo.extraRules = [
          {
            groups = [ "wheel" ];
            commands = [
              {
                command = "${pkgs.acl}/bin/setfacl";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "steam-as";
            # Explicitly do NOT include pkgs.sudo here. writeShellApplication
            # prepends runtimeInputs to PATH, so `pkgs.sudo` would shadow the
            # NixOS setuid wrapper at /run/wrappers/bin/sudo — and the raw
            # nix-store sudo binary isn't setuid, so every sudo -n call would
            # silently fail. Leaving sudo off the list lets the script's
            # bare `sudo` resolve via PATH to the setuid wrapper.
            runtimeInputs = [
              pkgs.gamescope
              pkgs.acl
              pkgs.systemd
            ];
            text = ''
              if [ $# -lt 1 ]; then
                cat <<'EOF' >&2
              usage: steam-as <user> [extra-gamescope-args...]

              Launches <user>'s Steam inside a nested gamescope compositor.
              Every game launched from that Steam inherits the controller
              filter — no per-game launch options required.

              Defaults: 2560x1440 windowed. Override via env or extra args:
                GAMESCOPE_W=1920 GAMESCOPE_H=1080 steam-as bri
                steam-as bri --prefer-output HDMI-A-2 -f

              Requires: <fleet.gaming/inputplumber> (virtual xbox target)
                        and <fleet.user/launch-as> (ego wrapper).
              EOF
                exit 64
              fi
              target="$1"
              shift

              # VID:PID of the InputPlumber virtual xbox-series target.
              # Baked in because InputPlumber always emits xbox-series for
              # our 90-desktop-gamepads.yaml composite config.
              VIRT_VID_PID="0x045e/0x0b12"

              W="''${GAMESCOPE_W:-2560}"
              H="''${GAMESCOPE_H:-1440}"

              # Kernel-level controller routing: grant the target user rw
              # on every joystick evdev node, and deny access to every
              # *other* real interactive local user. Steam Input bypasses
              # SDL env filters, so this is the only reliable block — a
              # non-target user's Steam gets EACCES when trying to open a
              # pad assigned to the target.
              #
              # sudo matches by absolute path, so the invocation must use
              # the nix-store setfacl binary that the sudoers rule names.
              SETFACL="${pkgs.acl}/bin/setfacl"
              for node in /dev/input/event*; do
                [ -e "$node" ] || continue
                joy=$(udevadm info -q property -n "$node" 2>/dev/null \
                  | grep -c "^ID_INPUT_JOYSTICK=1" || true)
                [ "$joy" -ge 1 ] || continue
                sudo -n "$SETFACL" -b "$node" 2>/dev/null || true
                sudo -n "$SETFACL" -m "u:''${target}:rw" "$node" 2>/dev/null || true
                # Iterate real interactive users (UID 1000-29999, login shell).
                # Process substitution keeps us in the current shell so the
                # loop iterates once per user.
                while IFS=: read -r user _ uid _ _ _ shell; do
                  [ "$uid" -ge 1000 ] && [ "$uid" -lt 30000 ] || continue
                  case "$shell" in
                    */nologin | */false) continue ;;
                  esac
                  [ "$user" = "$target" ] && continue
                  sudo -n "$SETFACL" -m "u:''${user}:---" "$node" 2>/dev/null || true
                done < <(getent passwd)
              done

              exec launch-as "$target" env \
                -u SDL_GAMECONTROLLER_IGNORE_DEVICES \
                SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT="$VIRT_VID_PID" \
                gamescope -W "$W" -H "$H" "$@" -- steam
            '';
          })
        ];
      };
  };
}
