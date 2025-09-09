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
  cfg = config.${namespace}.programs.protonvpn-gui;
in
{
  options.${namespace}.programs.protonvpn-gui = with types; {
    enable = mkBoolOpt false "Enable ProtonVPN GUI client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      protonvpn-gui
    ];
  };
}
