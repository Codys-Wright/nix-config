# RaySession audio sub-aspect (can be included independently)
{
  FTS,
  ...
}:
{
  FTS.hardware.audio._.raysession = {
    description = "RaySession audio session manager";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        stable.raysession
        python313Packages.legacy-cgi
      ];
    };
  };
}

