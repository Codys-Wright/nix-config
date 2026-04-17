{ fleet, ... }:
{
  fleet.user._.launch-as = {
    description = "Install ego and a `launch-as` wrapper for running GUI apps as another local user in the current graphical session (Wayland/XWayland/PipeWire sockets + xdg-desktop-portal handled automatically)";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.ego
          (pkgs.writeShellApplication {
            name = "launch-as";
            runtimeInputs = [ pkgs.ego ];
            text = ''
              if [ $# -lt 2 ]; then
                echo "usage: launch-as <user> <command> [args...]" >&2
                exit 64
              fi
              target="$1"
              shift
              exec ego -u "$target" -- "$@"
            '';
          })
        ];
      };
  };
}
