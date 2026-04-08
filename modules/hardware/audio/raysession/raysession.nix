# RaySession audio sub-aspect (can be included independently)
{
  fleet,
  ...
}:
{
  fleet.raysession = {
    description = "RaySession audio session manager";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (pkgs.stable.raysession.overridePythonAttrs (old: {
            dependencies = (old.dependencies or [ ]) ++ [ pkgs.stable.python313Packages.legacy-cgi ];
          }))
        ];
      };
  };
}
