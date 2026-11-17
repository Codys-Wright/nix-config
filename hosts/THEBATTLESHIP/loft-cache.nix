# THEBATTLESHIP pushes Loft's packages to loft.cachix.org (public), so the
# other hosts download them instead of compiling. The big one is
# loft-kwin-patched: all of KWin, rebuilt for Loft's two small patches.
#
# What is pushed: the store paths of the Loft flake's own packages
# (inputs.loft.packages), only those this host actually built, each with
# its closure. Cachix skips whatever cache.nixos.org already has, so that's
# Loft plus the patched KWin. No system closures, configs or home files.
#
# When: the unit's list changes whenever the Loft input does, so a switch
# with a new Loft restarts it and pushes. It also runs once at boot (a
# no-op when everything is already there). It runs in the background, so
# a switch never waits for an upload.
#
# Token: a Cachix write token for the `loft` cache, in
# /var/lib/loft-cache/cachix-token (root, 0600). It is put there by hand for
# now; moving it into nix-secrets (sops) is Keeper's. Without the file the
# unit is skipped.
{ inputs, ... }:
{
  den.aspects.THEBATTLESHIP-loft-cache = {
    description = "Push Loft's packages and the patched KWin to loft.cachix.org";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        tokenFile = "/var/lib/loft-cache/cachix-token";
        loftPkgs = lib.filterAttrs (
          n: v: n != "default" && lib.isDerivation v
        ) inputs.loft.packages.${pkgs.stdenv.hostPlatform.system};
        # Paths only, without their build context: listing a package must
        # not make this host build it.
        list = pkgs.writeText "loft-cache-paths" (
          lib.concatMapStrings (p: builtins.unsafeDiscardStringContext p.outPath + "\n") (
            lib.attrValues loftPkgs
          )
        );
      in
      {
        systemd.services.loft-cache-push = {
          description = "Push Loft's packages to loft.cachix.org";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "nix-daemon.socket"
          ];
          restartTriggers = [ list ];
          unitConfig.ConditionPathExists = tokenFile;
          path = [
            pkgs.cachix
            config.nix.package
          ];
          serviceConfig = {
            Type = "simple";
            RemainAfterExit = true;
            DynamicUser = true;
            CacheDirectory = "loft-cache";
            Environment = "HOME=/var/cache/loft-cache";
            LoadCredential = "token:${tokenFile}";
            Nice = 10;
            IOSchedulingClass = "idle";
          };
          script = ''
            paths=()
            while read -r p; do
              nix-store --check-validity "$p" 2>/dev/null && paths+=("$p")
            done < ${list}
            echo "loft-cache: ''${#paths[@]} of $(wc -l < ${list}) Loft packages are built here"
            [ "''${#paths[@]}" -gt 0 ] || exit 0
            CACHIX_AUTH_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/token")" cachix push loft "''${paths[@]}"
          '';
        };
      };
  };
}
