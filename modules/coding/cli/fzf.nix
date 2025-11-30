# Fzf - fuzzy finder with custom colors
{
  FTS, ... }:
{
  FTS.fzf = {
    description = "Fzf fuzzy finder with custom colors";

    homeManager = { pkgs, lib, ... }: {
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        tmux.enableShellIntegration = true;
        colors = lib.mkForce {
          "fg+" = "#007acc";
          "bg+" = "-1";
          "fg" = "#ffffff";
          "bg" = "-1";
          "prompt" = "#666666";
          "pointer" = "#007acc";
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
  };
}

