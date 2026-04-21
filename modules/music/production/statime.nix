# Statime fork for Inferno/Dante clock sync.
# This is now driven by a reusable helper in lib/inferno/common.nix.
{ fleet, lib, ... }:
let
  mkStatime = import ../../../lib/inferno/common.nix { inherit lib; };
in
{
  fleet.music._.production._.statime = {
    description = "Statime Inferno fork configured for Dante/PTPv1 on THEBATTLESHIP's 10G Dante NIC";

    nixos = mkStatime.mkStatimeNixos {
      name = "THEBATTLESHIP";
      deviceName = "Galaxy32";
      interface = "enp12s0";
      interfaceComment = "Verified via netaudio discovery: Dante devices are visible on the 10G link enp12s0 (10.10.10.10), not on enp11s0.";
      preferredLeaderArgs = [
        "--name"
        "AA-4202524000109"
        "device"
        "config"
        "preferred-leader"
        "on"
      ];
    };
  };
}
