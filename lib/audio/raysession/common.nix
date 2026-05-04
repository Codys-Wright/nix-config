{ lib }:
{
  mkRaysessionPackage =
    pkgs:
    pkgs.stable.raysession.overridePythonAttrs (old: {
      dependencies = (old.dependencies or [ ]) ++ [ pkgs.stable.python313Packages.legacy-cgi ];
    });
}
