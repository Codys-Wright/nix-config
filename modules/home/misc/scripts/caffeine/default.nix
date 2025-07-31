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
  cfg = config.${namespace}.misc.scripts.caffeine;

  caffeine-status = pkgs.writeShellScriptBin "caffeine-status" ''
    [[ $(pidof "hypridle") ]] && echo "0" || echo "1"
  '';

  caffeine-status-icon = pkgs.writeShellScriptBin "caffeine-status-icon" ''
    [[ $(pidof "hypridle") ]] && echo "󰾪" || echo "󰅶"
  '';

  caffeine = pkgs.writeShellScriptBin "caffeine" ''
    if [[ $(pidof "hypridle") ]]; then
      systemctl --user stop hypridle.service
      title="󰅶  Caffeine Activated"
      description="Caffeine is now active! Your screen will not turn off automatically."
    else
      systemctl --user start hypridle.service
      title="󰾪  Caffeine Deactivated"
      description="Caffeine is now deactivated! Your screen will turn off automatically."
    fi

    notif "caffeine" "$title" "$description"
  '';
in
{
  options.${namespace}.misc.scripts.caffeine = with types; {
    enable = mkBoolOpt false "Enable misc.scripts.caffeine";
  };

  config = mkIf cfg.enable {
    home.packages = [
      caffeine-status
      caffeine
      caffeine-status-icon
    ];
  };
}
