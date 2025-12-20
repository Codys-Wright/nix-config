# Eza - modern ls replacement
{
  FTS.coding._.cli._.eza = {
    description = "Eza modern ls replacement";

    homeManager = {...}: {
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
  };
}
