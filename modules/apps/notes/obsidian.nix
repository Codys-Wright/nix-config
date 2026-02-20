# Obsidian - Knowledge base and note-taking application
{
  FTS.apps._.notes._.obsidian = {
    description = "Obsidian - Powerful knowledge base on top of a local folder of plain text Markdown files";

    homeManager = {pkgs, lib, ...}: {
      programs.obsidian.enable = true;
      home.packages = [pkgs.obsidian];
      home.activation.ensureObsidianConfigDir = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        mkdir -p "$HOME/.config/obsidian"
      '';
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.obsidian];
    };
  };
}
