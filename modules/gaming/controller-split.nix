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

        # Wrapper env — same as main.rs sets, but present for direct CLI
        # runs from whatever shell state the user has. Belt + suspenders.
        environment.variables = {
          NO_AT_BRIDGE = "1";
          GTK_A11Y = "none";
        };
      };
  };
}
