{
  config,
  lib,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.home-manager;
in
{
  options.${namespace}.programs.home-manager = with types; {
    extraOptions = mkOpt attrs { } "${namespace}.programs.home-manager.extraOptions";
  };

  config = {
    snowfallorg.users.${config.${namespace}.config.user.name}.home.config =
      config.${namespace}.programs.home-manager.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "bk4";
    };
  };
}
