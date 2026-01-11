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

      # Symlink REAPER extensions to UserPlugins directory
      home.file.".config/REAPER/UserPlugins/reaper_sws-x86_64.so".source =
        "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so";
      home.file.".config/REAPER/UserPlugins/reaper_reapack-x86_64.so".source =
        "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so";

      # Symlink SWS Python scripts
      home.file.".config/REAPER/Scripts/sws_python.py".source =
        "${pkgs.reaper-sws-extension}/Scripts/sws_python.py";
      home.file.".config/REAPER/Scripts/sws_python64.py".source =
        "${pkgs.reaper-sws-extension}/Scripts/sws_python64.py";
    };
  };
}
