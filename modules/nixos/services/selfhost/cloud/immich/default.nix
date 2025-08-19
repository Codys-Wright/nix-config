{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.selfhost.cloud.immich;
in
{
  options.${namespace}.services.selfhost.cloud.immich = with types; {
    enable = mkBoolOpt false "Enable immich";
  };

  # Fix until immich is in stable
  # disabledModules = [ "services/web-apps/immich.nix" ];
  # imports = [ "${inputs.unstable}/nixos/modules/services/web-apps/immich.nix" ];

  config = mkIf cfg.enable {
    services.immich = {
      enable = true;

      port = 3001;
      # package = inputs.unstable.legacyPackages.x86_64-linux.immich;
      host = "0.0.0.0";
      mediaLocation = "/mnt/storage/immich";

      accelerationDevices = null;

      machine-learning = {
        enable = true;
      };
      redis = {
        enable = true;
        host = "0.0.0.0";
        port = 6379;
      };

      environment = {
        TZ = "Europe/Zurich";
      };

      database = {
        enable = true;
      };
    };
  };
}
