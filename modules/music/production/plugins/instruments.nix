# Virtual instrument plugins
{
  FTS,
  ...
}:
{
  FTS.music._.production._.plugins._.instruments = {
    description = "Virtual instrument plugins for music production";

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        vital
      ];
    };
  };
}
