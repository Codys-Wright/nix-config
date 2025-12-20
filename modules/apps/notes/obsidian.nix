# Obsidian - Knowledge base and note-taking application
{
  FTS.apps._.notes._.obsidian = {
    description = "Obsidian - Powerful knowledge base on top of a local folder of plain text Markdown files";

    homeManager = {pkgs, ...}: {
      programs.obsidian.enable = true;
      home.packages = [pkgs.obsidian];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.obsidian];
    };
  };
}
