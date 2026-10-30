# Creative tooling aggregator (design, photo, video, office).
# Usage: <fleet/creative>
{ fleet, __findFile, ... }:
{
  fleet.creative = {
    description = "Creative tooling: the ArtCraft suite";

    includes = [
      <fleet.creative/artcraft>
    ];
  };
}
