{ fleet, ... }:
{
  fleet.gaming._.inputplumber = {
    description = "InputPlumber gamepad router — one virtual xbox-series target per physical controller, for per-Steam-instance routing at runtime via `inputplumber` CLI";

    nixos =
      { pkgs, ... }:
      {
        services.inputplumber.enable = true;

        # Composite-device config for generic desktop controllers. Shipped
        # configs in nixpkgs all target handheld hardware (Ayaneo, GPD,
        # Legion Go, etc.) and never match a desktop with hot-plugged pads.
        # This config matches any DualSense / Xbox-family controller by
        # hidraw VID:PID and limits one physical source per composite
        # (`maximum_sources: 1`), so every connected pad becomes its own
        # virtual xbox-series target. Each Steam instance can then whitelist
        # one virtual pad via SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT.
        environment.etc."inputplumber/devices.d/90-desktop-gamepads.yaml".text = ''
          version: 1
          kind: CompositeDevice
          name: Desktop Gamepad

          # Always apply — not tied to DMI hardware fingerprint.
          matches: []

          # One physical pad = one virtual composite = one virtual xbox-series.
          maximum_sources: 1

          source_devices:
            # Sony DualSense (USB + BT)
            - group: gamepad
              hidraw:
                vendor_id: 0x054c
                product_id: 0x0ce6
            # Sony DualSense Edge
            - group: gamepad
              hidraw:
                vendor_id: 0x054c
                product_id: 0x0df2
            # Xbox Wireless Controller (Series X/S, 2020)
            - group: gamepad
              hidraw:
                vendor_id: 0x045e
                product_id: 0x0b13
            # Xbox Wireless Controller (Series X/S, Bluetooth)
            - group: gamepad
              hidraw:
                vendor_id: 0x045e
                product_id: 0x0b20
            # Xbox One Controller (wired)
            - group: gamepad
              hidraw:
                vendor_id: 0x045e
                product_id: 0x02ea
            # Xbox One Elite Series 2
            - group: gamepad
              hidraw:
                vendor_id: 0x045e
                product_id: 0x0b00

          options:
            auto_manage: true

          target_devices:
            - xbox-series
        '';

        # Thin helpers around `inputplumber` CLI. Daemon CLI is the source
        # of truth; these just give short memorable names for the two most
        # common ops.
        environment.systemPackages = [
          (pkgs.writeShellApplication {
            name = "pad-list";
            runtimeInputs = [ pkgs.inputplumber ];
            text = ''
              echo "=== composite devices (virtual pads) ==="
              inputplumber devices list
              echo
              echo "=== player order ==="
              inputplumber devices order list 2>/dev/null || true
            '';
          })

          (pkgs.writeShellApplication {
            name = "pad-order";
            runtimeInputs = [ pkgs.inputplumber ];
            text = ''
              if [ $# -lt 1 ]; then
                echo "usage: pad-order <composite-id-1> [<composite-id-2> ...]"
                echo "       run pad-list to see composite IDs"
                echo ""
                echo "Sets the player-slot order: first arg = player 1, second = player 2, ..."
                echo "Games using SDL_JOYSTICK_DEVICE_INDEX will see them in this order."
                exit 64
              fi
              inputplumber devices order set "$@"
            '';
          })
        ];
      };
  };
}
