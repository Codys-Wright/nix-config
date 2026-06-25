# Guitar processing tools — amp sims, FX chains, plugin host.
{ fleet, ... }:
{
  fleet.music._.production._.guitar = {
    description = "Guitar amp simulators and processing tools";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux (
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
          ]
        );
      };
  };
}
