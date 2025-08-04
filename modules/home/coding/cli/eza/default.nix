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
  cfg = config.${namespace}.coding.cli.eza;
in
{
  options.${namespace}.coding.cli.eza = with types; {
    enable = mkBoolOpt false "Enable eza modern ls replacement";
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
