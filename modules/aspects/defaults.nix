{ __findFile, den, ... }:
{
  den.default = {
    includes = [
      <den/define-user>
      den.aspects.hm
      den._.inputs'
      den._.self'
      <fleet/base-host>
      <fleet/nix-settings>
      <fleet/state-version>
      <fleet/no-man-cache>
      den._.hostname
    ];
    home.includes = [
      <fleet/nix>
      <fleet/user-secrets>
    ];
  };

  # NOTE: cross-entity routing (host aspects with homeManager blocks
  # contributing to users and vice versa) is built into den's pipeline now;
  # the old `den._.mutual-provider` battery is an inert compatibility shim
  # and its include was removed when bumping den past 2026-07.
}
