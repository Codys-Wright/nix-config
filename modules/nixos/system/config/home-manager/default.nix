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
      useUserPackages = false;
      useGlobalPkgs = false;
      backupFileExtension = "backup_ksadjfsj";
    };

    # Ensure home-manager services wait for Nix daemon
    systemd.services.home-manager-cody = {
      after = [ "nix-daemon.service" "network.target" ];
      wants = [ "nix-daemon.service" ];
      requires = [ "nix-daemon.service" ];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
