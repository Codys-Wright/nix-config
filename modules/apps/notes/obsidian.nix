# Obsidian - Knowledge base and note-taking application
{
  FTS,
  ...
}:
{
  FTS.apps._.notes._.obsidian = {
    description = "Obsidian - Powerful knowledge base on top of a local folder of plain text Markdown files";

    homeManager = { pkgs, lib, ... }: {
      programs.obsidian.enable = true;
      home.packages = [ pkgs.obsidian ];
    };

    nixos = { pkgs, lib, ... }: {
      environment.systemPackages = [ pkgs.obsidian ];
    };
  };
}

