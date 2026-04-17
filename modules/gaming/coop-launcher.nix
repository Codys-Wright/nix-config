{ fleet, ... }:
{
  fleet.gaming._.coop-launcher = {
    description = "steam-as wrapper — launches another local user's Steam inside a nested gamescope compositor with SDL filters set so only their assigned virtual InputPlumber pad is visible. Every game launched from that Steam inherits the filter, so there's nothing to configure per-game.";

    nixos =
      { pkgs, ... }:
      {
        # Hide the InputPlumber-emitted virtual xbox-series pad (045e:0b12)
        # from every user's Steam by default. `steam-as` unsets this and
        # sets _EXCEPT instead, so only the target user's gamescoped Steam
        # sees the virtual pad. New logins get the env; currently-running
        # Steams need a restart (or a per-game launch-option override).
        environment.sessionVariables.SDL_GAMECONTROLLER_IGNORE_DEVICES = "0x045e/0x0b12";

        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "steam-as";
            runtimeInputs = [ pkgs.gamescope ];
            text = ''
              if [ $# -lt 1 ]; then
                cat <<'EOF' >&2
              usage: steam-as <user> [extra-gamescope-args...]

              Launches <user>'s Steam inside a nested gamescope compositor.
              Every game launched from that Steam inherits the controller
              filter — no per-game launch options required.

              Defaults: 1920x1080 windowed. Override via env or extra args:
                GAMESCOPE_W=2560 GAMESCOPE_H=1440 steam-as bri
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

              W="''${GAMESCOPE_W:-1920}"
              H="''${GAMESCOPE_H:-1080}"

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
