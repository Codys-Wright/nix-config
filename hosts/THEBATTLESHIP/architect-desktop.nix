# Architect's desktop app for cody on THEBATTLESHIP: the release's own
# AppImage, wrapped by Architect's own package (architect
# nix/desktop/package.nix), so installing compiles nothing.
#
# The input is the repo as plain source (`flake = false`): only the package
# file is used, so none of Architect's own flake inputs are locked here.
# Which release it installs is architect's nix/desktop/source.json at the
# locked commit: `nix flake update architect`, then switch. The app can also
# update itself between bumps: its launcher runs the newer of the store's
# image and the one its updater put in ~/.local/share/architect/updates.
{ inputs, ... }:
{
  flake-file.inputs.architect = {
    url = "github:FastTrackStudios/architect";
    flake = false;
  };

  den.aspects."cody@THEBATTLESHIP".homeManager =
    { pkgs, ... }:
    {
      home.packages = [ (pkgs.callPackage "${inputs.architect}/nix/desktop/package.nix" { }) ];
    };
}
