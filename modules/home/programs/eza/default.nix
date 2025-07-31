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
  cfg = config.${namespace}.programs.eza;
in
{
  options.${namespace}.programs.eza = with types; {
    enable = mkBoolOpt false "Enable programs.eza";
  };

  config = mkIf cfg.enable {
    programs.eza = {
      enable = true;
      icons = "auto";

      extraOptions = [
        "--group-directories-first"
        "--no-quotes"
        "--git-ignore"
        "--icons=always"
      ];
    };
  };
}
