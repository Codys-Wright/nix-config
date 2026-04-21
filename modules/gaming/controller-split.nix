{ fleet, inputs, ... }:
{
  flake-file.inputs.controller-split = {
    url = "path:/home/cody/Development/Tools/controller-split";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.gaming._.controller-split = {
    description = "controller-split — Dioxus tray+window + CLI that maps physical gamepads to users via InputPlumber. Absorbs launch-as / coop-launcher — enable this and you can drop those.";

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [ inputs.controller-split.nixosModules.default ];

        services.controller-split = {
          enable = true;
          enableInputPlumber = false;
          enableUserAutostart = false;
          allowedUsers = [
            "cody"
            "bri"
            "joshua"
            "guest"
          ];
        };

        # Temporary host-level lockout: keep cody off every controller node
        # so only bri can read gamepad input at the kernel layer.
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="controller-split-deny-cody-input.service"
          ACTION=="add|change", SUBSYSTEM=="hidraw", TAG+="systemd", ENV{SYSTEMD_WANTS}+="controller-split-deny-cody-input.service"
        '';

        systemd.services.controller-split-deny-cody-input = {
          description = "Deny cody access to controller input nodes";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-udevd.service" ];
          serviceConfig.Type = "oneshot";
          script = ''
            set -eu

            SETFACL="${pkgs.acl}/bin/setfacl"
            UDEVDM="${pkgs.udev}/bin/udevadm"

            is_controller() {
              node="$1"
              props="$($UDEVDM info -q property -n "$node" 2>/dev/null || true)"
              vid="$(printf '%s\n' "$props" | sed -n 's/^ID_VENDOR_ID=//p' | head -n1)"
              pid="$(printf '%s\n' "$props" | sed -n 's/^ID_MODEL_ID=//p' | head -n1)"

              case "$vid:$pid" in
                054c:0ce6|054c:0df2|2dc8:201a|045e:0b13|045e:0b20|045e:02ea|045e:0b00)
                  return 0
                  ;;
              esac

              printf '%s\n' "$props" | grep -q '^ID_INPUT_JOYSTICK=1$'
            }

            fence_node() {
              node="$1"
              [ -e "$node" ] || return 0
              is_controller "$node" || return 0

              $SETFACL -b "$node" || true
              $SETFACL -m g::--- "$node" || true
              $SETFACL -m o::--- "$node" || true
              $SETFACL -m u:bri:rw "$node" || true
              $SETFACL -m u:cody:--- "$node" || true
            }

            for node in /dev/input/event* /dev/input/js* /dev/hidraw*; do
              fence_node "$node"
            done
          '';
        };

        # Wrapper env — same as main.rs sets, but present for direct CLI
        # runs from whatever shell state the user has. Belt + suspenders.
        environment.sessionVariables = {
          NO_AT_BRIDGE = "1";
          GTK_A11Y = "none";
        };
      };
  };
}
