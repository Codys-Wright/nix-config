# RaySession audio sub-aspect (can be included independently)
{
  FTS,
  ...
}:
{
  FTS.raysession = {
    description = "RaySession audio session manager";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        stable.raysession
        python313Packages.legacy-cgi
      ];
    };
  };
}

