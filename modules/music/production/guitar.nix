# Guitar processing tools — amp sims, FX chains, plugin host.
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  # tone3000 (NAM/IR player) landed in nixpkgs after the main pin; take just
  # that package from a dedicated input instead of bumping all of nixpkgs.
  # Drop this input once the main nixpkgs pin includes tone3000.
  flake-file.inputs.nixpkgs-tone3000.url = lib.mkDefault "github:nixos/nixpkgs/2786a2a72088ecf32aea5b3ec52099e6a7cff78f";

  fleet.music._.production._.guitar = {
    description = "Guitar amp simulators and processing tools";

    homeManager =
      { pkgs, lib, ... }:
      let
        pkgsTone3000 = import inputs.nixpkgs-tone3000 {
          system = pkgs.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      in
      {
        home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
          with pkgs;
          [
            guitarix # Guitar amp simulator + effects, JACK-native
            gxplugins-lv2 # Extra Guitarix amp/fx as LV2 plugins
            carla # Plugin host — loads LV2/VST/LADSPA in a pedalboard UI
            rakarrack # Multi-effects guitar processor
            caps # C* Audio Plugin Suite (amp sim, reverb, chorus)
            x42-plugins # LV2 collection including guitar tuner + amp
            zam-plugins # Tube amp sim, dynamics, EQ
            rkrlv2 # Rakarrack effects ported to LV2
            pkgsTone3000.tone3000 # NAM capture/IR player: standalone + VST3/LV2/CLAP
          ]
        );
      };
  };
}
