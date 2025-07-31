{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.nh;
  user = config.${namespace}.config.user;
in
{
  options.${namespace}.programs.nh = {
    enable = mkBoolOpt false "${namespace}.programs.zsh.enable";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      #flake = "~/.nixcfg";
    };
  };
}
