# The shared kache store (kache.nix) inside the nix build sandbox, for the
# builds that ask for it: studio's release image (`FTS_NIX_KACHE=1 nix build
# --impure .#studio-web-image`, studio nix/modules/crane.nix) wraps rustc in
# kache, so a release restores the crates the last one compiled. A build
# that does not set RUSTC_WRAPPER never touches the store; its hashes and
# outputs are what they were.
#
# The precedent is nixpkgs' `programs.ccache`: the cache directory in
# `extra-sandbox-paths`, writable by group `nixbld`. Group `nixbld`, not
# `kache`: the Linux sandbox drops a build user's supplementary groups
# before it enters its user namespace (libstore `setgroups(0, 0)`, and the
# namespace's gid_map holds the build group alone), so making the nixbld*
# users members of `kache` would give a sandboxed build nothing. nixbld is
# their primary group, so the store gets ACL entries for it, beside `kache`'s:
#
#   - the store's own ACL and default ACL gain `g:nixbld:rwx`, so whatever
#     anyone creates in it from now on is readable and writable by builds;
#   - what is already there gets the same entry once (a stamp records it),
#     with `-n`: the mask kache set on a file stays as it was, so a build
#     reaches a blob exactly as far as group `kache` does. The users' private
#     OUT_DIR alias roots (`out-dirs*`) are left alone: kache refuses a root
#     anyone else can write.
#
# The second path is where those builds put their cargo target dir. A
# restore is a reflink, and a reflink (like a hardlink) cannot cross
# filesystems: the sandbox's build dir is under /nix (another disk), so a
# target dir there would copy every restored byte. The build points its
# target dir here instead, on the store's btrfs (a reflink across two bind
# mounts of one filesystem is fine since Linux 5.18; a hardlink is not, and
# kache reflinks on btrfs). Scoped this way rather than with nix's global
# `build-dir`, which would move every build's temp dir onto a drive that is
# mounted late and can be missing. The build removes its own dir when it
# ends; one that was killed is swept by the next (anything older than a
# day), which the default ACL lets any build user do.
#
# Both paths end in `?`: optional, so with the drive missing every build
# still runs (studio's falls back to building without kache).
#
# The cost: any sandboxed build on this host can write the store, as any
# member of `kache` already can. Only trusted users and the FastTrackStudios
# runners build here.
{ ... }:
let
  store = "/run/media/Development/.kache";
  builds = "/run/media/Development/.kache-nix-builds";
in
{
  den.aspects.THEBATTLESHIP-kache-nix-sandbox = {
    description = "The shared kache store inside the nix sandbox (group nixbld), and a target-dir scratch on the same btrfs";
    nixos =
      { pkgs, ... }:
      {
        nix.settings.extra-sandbox-paths = [
          "${store}?"
          "${builds}?"
        ];

        # After kache-store.service has made the store and set its ACL.
        systemd.services.kache-nix-sandbox = {
          description = "Open the shared kache store to sandboxed nix builds (group nixbld)";
          wantedBy = [ "run-media-Development.mount" ];
          after = [
            "run-media-Development.mount"
            "kache-store.service"
          ];
          requires = [ "kache-store.service" ];
          bindsTo = [ "run-media-Development.mount" ];
          path = [
            pkgs.acl
            pkgs.coreutils
            pkgs.findutils
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            store=${store}
            # kache-store.service resets the store's own ACL on every start.
            setfacl -m g:nixbld:rwx,d:g:nixbld:rwx "$store"
            stamp="$store/.nixbld-acl-v1"
            if [ ! -e "$stamp" ]; then
              find "$store" -mindepth 1 -path "$store/out-dirs*" -prune -o -type d -print0 \
                | xargs -0r setfacl -n -m g:nixbld:rwx,d:g:nixbld:rwx \
                || echo "some directories kept their ACL (removed while this ran?)" >&2
              find "$store" -mindepth 1 -path "$store/out-dirs*" -prune -o -type f -print0 \
                | xargs -0r setfacl -n -m g:nixbld:rwx \
                || echo "some files kept their ACL (removed while this ran?)" >&2
              touch "$stamp"
            fi

            builds=${builds}
            install -d -m 0770 -o root -g nixbld "$builds"
            setfacl -m g:nixbld:rwx,d:g:nixbld:rwx,d:u::rwx,d:m::rwx,d:o::--- "$builds"
          '';
        };
      };
  };
}
