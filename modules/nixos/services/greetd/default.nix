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
  cfg = config.${namespace}.services.greetd;
  name = "ryan";
in
{
  options.${namespace}.services.greetd = with types; {
    enable = mkBoolOpt false "Enable greetd";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session.command = pkgs.writeShellScript "greeter" ''
        export XKB_DEFAULT_LAYOUT=${config.services.xserver.xkb.layout}
        export XCURSOR_THEME=Qogir
        ${name}/bin/greeter
      '';
    };

    systemd.tmpfiles.rules = [ "d '/var/cache/greeter' - greeter greeter - -" ];
  };
}
