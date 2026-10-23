# gh-stack - GitHub's native stacked PRs from the CLI (`gh stack …`)
{
  fleet,
  ...
}:
{
  fleet.coding._.cli._.gh-stack = {
    description = "gh-stack — GitHub's official gh extension for native stacked pull requests";

    homeManager =
      { pkgs, ... }:
      let
        pkg = pkgs.fleet-gh-stack;
      in
      {
        # gh finds an extension at $XDG_DATA_HOME/gh/extensions/gh-<name>/gh-<name>
        # (what home-manager's programs.gh.extensions links; gh itself is not
        # managed through programs.gh here, so its config stays the user's).
        xdg.dataFile."gh/extensions/gh-stack/gh-stack".source = "${pkg}/bin/gh-stack";

        # The agent skill shipped with the release, pinned to the same tag as
        # the binary. Owns only ~/.claude/skills/gh-stack/.
        home.file.".claude/skills/gh-stack".source = "${pkg}/share/skills/gh-stack";
      };
  };
}
