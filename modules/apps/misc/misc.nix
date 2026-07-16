# Miscellaneous apps aggregator
#
# Deliberately NOT in this facet: cuteatum, opendeck, unshuffle — they are
# cody-specific studio tools (ATEM control, Stream Deck, sample-library
# management), included directly in users/cody/cody.nix so the other users
# of <fleet/apps> don't get them. Add a leaf here only if every consumer
# of the apps facet should have it.
{ fleet, ... }:
{
  fleet.apps._.misc = {
    description = "Miscellaneous apps - AppImage, Flameshot, LocalSend, Nextcloud";
    includes = [
      fleet.apps._.misc._.appimage
      fleet.apps._.misc._.flameshot
      fleet.apps._.misc._.localsend
      fleet.apps._.misc._.nextcloud-client
    ];
  };
}
