# network-audio-controller / netaudio CLI
# Dante discovery and control CLI for THEBATTLESHIP
{ fleet, ... }:
{
  fleet.audio._.dante._.netaudio = {
    description = "netaudio CLI for discovering and controlling Dante/network audio devices";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.netaudio
        ];
      };
  };
}
