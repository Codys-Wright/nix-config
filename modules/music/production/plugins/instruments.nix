# Virtual instrument plugins
{
  FTS,
  ...
}:
{
  FTS.music._.production._.plugins._.instruments = {
    description = "Virtual instrument plugins for music production";

    homeManager = { pkgs, lib, ... }: {
      home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
        vital
      ]);
    };
  };
}
