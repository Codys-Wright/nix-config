# Task's desktop app for cody on THEBATTLESHIP: the release's own AppImage,
# wrapped (packages/task-desktop), so installing compiles nothing. Bump it to
# a new release with packages/task-desktop/update.sh, then switch.
{
  den.aspects."cody@THEBATTLESHIP".homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.task-desktop ];
    };
}
