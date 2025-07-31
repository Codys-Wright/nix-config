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
  cfg = config.${namespace}.programs.fzf;

  accent = "#" + config.lib.stylix.colors.base0D;
  foreground = "#" + config.lib.stylix.colors.base05;
  muted = "#" + config.lib.stylix.colors.base03;
in
{
  options.${namespace}.programs.fzf = with types; {
    enable = mkBoolOpt false "Enable programs.fzf";
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
