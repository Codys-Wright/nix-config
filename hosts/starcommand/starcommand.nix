{
  inputs,
  den,
  pkgs,
  FTS,
  __findFile,
  ...
}: {
  # TEMPORARILY DISABLED: starcommand host with broken selfhostblocks patches
  # The patches are incompatible with current nixpkgs version (nixpkgs is ~1 month newer than selfhostblocks)
  # Patches failing: lldap patch with 5 hunks, 2 FAILED
  #
  # To re-enable:
  # 1. Update selfhostblocks to a version with patches compatible with current nixpkgs
  # 2. Or pin nixpkgs to a version compatible with the selfhostblocks patches
  # 3. Or manually update the patches to apply cleanly to current nixpkgs
  #
  # See hosts/THEBATTLESHIP/THEBATTLESHIP.nix for a working desktop config without selfhost services

  den.hosts.x86_64-linux = {};

  # starcommand host aspects are also disabled pending patch fixes
  den.aspects = {};
}
