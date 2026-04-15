# Game development tools aspect
{
  fleet,
  ...
}:
{
  fleet.coding._.tools._.game-dev = {
    description = "Game development tools — Godot engine and dependencies";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = with pkgs; [
          godot_4
          blender
        ];
      };
  };
}
