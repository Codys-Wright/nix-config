# Reaper DAW with extensions
{
  FTS,
  ...
}:
{
  FTS.music._.production._.reaper = {
    description = "Reaper digital audio workstation with SWS and ReaPack extensions";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        reaper
        reaper-sws-extension
        reaper-reapack-extension
      ];
    };

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        reaper
        reaper-sws-extension
        reaper-reapack-extension
      ];
    };
  };
}
