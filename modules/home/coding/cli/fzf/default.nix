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
  cfg = config.${namespace}.coding.cli.fzf;

  accent = "#" + config.lib.stylix.colors.base0D;
  foreground = "#" + config.lib.stylix.colors.base05;
  muted = "#" + config.lib.stylix.colors.base03;
in
{
  options.${namespace}.coding.cli.fzf = with types; {
    enable = mkBoolOpt false "Enable fzf fuzzy finder";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = lib.mkForce {
        "fg+" = accent;
        "bg+" = "-1";
        "fg" = foreground;
        "bg" = "-1";
        "prompt" = muted;
        "pointer" = accent;
      };
      defaultOptions = [
        "--margin=1"
        "--layout=reverse"
        "--border=rounded"
        "--info='hidden'"
        "--header=''"
        "--prompt='/ '"
        "-i"
        "--no-bold"
      ];
    };
  };
}
