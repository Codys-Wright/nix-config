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
  cfg = config.${namespace}.desktop.hyprland.modules.scripts.hyprpanel;

  hyprpanel-toggle = pkgs.writeShellScriptBin "hyprpanel-toggle" ''
    hyprpanel -t bar-0
    hyprpanel -t bar-1
    hyprpanel -t bar-2
    hyprpanel -t bar-3
  '';

  hyprpanel-hide = pkgs.writeShellScriptBin "hyprpanel-hide" ''
    status=$(hyprpanel -r "isWindowVisible('bar-0')")
    if [[ $status == "true" ]]; then
      hyprpanel -t bar-0
    fi
    status=$(hyprpanel -r "isWindowVisible('bar-1')")
    if [[ $status == "true" ]]; then
      hyprpanel -t bar-1
    fi
  '';

  hyprpanel-show = pkgs.writeShellScriptBin "hyprpanel-show" ''
    status=$(hyprpanel -r "isWindowVisible('bar-0')")
    if [[ $status == "false" ]]; then
      hyprpanel -t bar-0
    fi
    status=$(hyprpanel -r "isWindowVisible('bar-1')")
    if [[ $status == "false" ]]; then
      hyprpanel -t bar-1
    fi
  '';

  hyprpanel-reload = pkgs.writeShellScriptBin "hyprpanel-reload" ''
    [ $(pgrep "ags") ] && pkill ags
    hyprctl dispatch exec hyprpanel
  '';
in
{
  options.${namespace}.desktop.hyprland.modules.scripts.hyprpanel = with types; {
    enable = mkBoolOpt false "Enable Hyprland panel control scripts";
  };

  config = mkIf cfg.enable {
    home.packages = [
      hyprpanel-toggle
      hyprpanel-reload
      hyprpanel-hide
      hyprpanel-show
    ];
  };
}
