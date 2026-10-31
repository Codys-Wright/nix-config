# kache: a content-addressed build cache for Rust (and C/C++), as Cargo's
# rustc wrapper. Two target dirs of the same code (a worktree per agent, a
# second checkout) restore each other's compiled crates instead of
# recompiling them; restored files are hardlinked/reflinked from the store, so
# the store must be on the same mount as the build trees (a host with its
# builds on another disk points it there: hosts/THEBATTLESHIP/storage.nix).
#
# Replaces sccache, which keyed on the target dir's path and so never shared
# anything between worktrees, and refused dx's own rustc wrapper.
{ ... }:
{
  fleet.coding._.lang._.kache = {
    description = "kache build cache as Cargo's rustc-wrapper, with its daemon as a user service";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = [ pkgs.kache ];

        # Cargo's own config, so every cargo — a shell, an agent, an editor
        # task, `just` — goes through kache; an exported RUSTC_WRAPPER only
        # reaches the shells that set it.
        home.file.".cargo/config.toml".text = ''
          [net]
          git-fetch-with-cli = true

          [build]
          rustc-wrapper = "${lib.getExe pkgs.kache}"
        '';

        # The daemon publishes to the store and keeps it within its budget;
        # without it kache still caches, more slowly.
        systemd.user.services.kache = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          Unit.Description = "kache build cache daemon";
          Service = {
            ExecStart = "${lib.getExe pkgs.kache} daemon run";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
