{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.security;
in
{
  options.${namespace}.services.security = with types; {
    enable = mkBoolOpt false "Enable security";
  };

  config = mkIf cfg.enable {
    security = {
      pam.services.swaylock = {
        text = ''
          auth include login
        '';
      };

      polkit = {
        enable = true;
        extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (
              subject.isInGroup("users")
                && (
                  action.id == "org.freedesktop.login1.reboot" ||
                  action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                  action.id == "org.freedesktop.login1.power-off" ||
                  action.id == "org.freedesktop.login1.power-off-multiple-sessions"
                )
              )
            {
              return polkit.Result.YES;
            }
          })
        '';
      };

      rtkit.enable = true;
    };
  };
}
