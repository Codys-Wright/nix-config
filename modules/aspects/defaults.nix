{ __findFile, den, ... }:
{
  # Every scope — hosts, host users and standalone homes. Only things that
  # are meaningful everywhere (or carry both an OS and a home half) go here;
  # den.default content lands once per target even though it is walked in
  # each scope.
  den.default.includes = [
    <den/define-user>
    den._.inputs'
    den._.self'
    <fleet/state-version> # nixos + darwin + homeManager halves
    <fleet/nix> # nixpkgs policy/overlays (os) + nix-index etc. (homeManager)
    <fleet/user-secrets> # homeManager
    den.aspects.hm # home-manager CLI (homeManager)
    <fleet/base-host> # system facet (os) + nh (os + homeManager)
    <fleet/no-man-cache> # os + homeManager
  ];

  # Hosts only (den docs: prefer schema includes over den.default for
  # host-level settings).
  den.schema.host.includes = [
    <fleet/nix-settings>
    den._.hostname
  ];

  # NOTE: cross-entity routing (host aspects with homeManager blocks
  # contributing to users and vice versa) is built into den's pipeline now;
  # the old `den._.mutual-provider` battery is an inert compatibility shim
  # and its include was removed when bumping den past 2026-07.
}
