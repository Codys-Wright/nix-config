# Shell tools meta-aspect - includes all shell modules
{
  FTS, ... }:
{
  FTS.shells = {
    description = "All shell modules - includes zsh, fish, starship, and powerlevel10k";

    includes = [
      FTS.zsh
      FTS.fish
      # FTS.starship
      FTS.nushell
      FTS.oh-my-posh
    ];
  };
}

