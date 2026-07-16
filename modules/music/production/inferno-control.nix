# inferno-control — CLI for discovering and controlling Dante /
# Inferno-AoIP devices over the wire (`device list`, `channel list`,
# `subscription add`, `device probe`, `device meter`, `flow list`,
# `device lock-state`, etc.). Pairs with the inferno_aoip soundcards
# this flake deploys; useful for ad-hoc inspection from any host on
# the Dante network without firing up Dante Controller.
{ fleet, inputs, ... }:
{
  flake-file.inputs.inferno-control = {
    # Canonical home is Codeberg (github copy is a leftover mirror).
    url = "git+https://codeberg.org/FastTrackStudios/inferno-control";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  fleet.music._.production._.inferno-control = {
    description = "inferno-control — Rust CLI for Dante / Inferno-AoIP control";

    nixos =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        environment.systemPackages = [
          inputs.inferno-control.packages.${system}.inferno-control
        ];
      };
  };
}
