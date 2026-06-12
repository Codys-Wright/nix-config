# ZSA keyboard hardware aspect (Moonlander, Voyager, Ergodox EZ, Planck EZ)
# hardware.keyboard.zsa ships ZSA's udev rules as 50-oryx.rules/50-wally.rules
# (Oryx web flashing, live training, Wally/Keymapp DFU). nixpkgs' rules use
# TAG+="uaccess" (logind session ACLs), so no plugdev group is needed.
{
  fleet,
  ...
}:
{
  fleet.hardware._.zsa = {
    description = "ZSA keyboard support — udev rules (uaccess), keymapp";

    nixos =
      { pkgs, ... }:
      {
        hardware.keyboard.zsa.enable = true;

        # GUI flashing / live training app
        environment.systemPackages = [ pkgs.keymapp ];
      };
  };
}
