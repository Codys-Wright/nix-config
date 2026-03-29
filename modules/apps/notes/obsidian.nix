# Obsidian - Knowledge base and note-taking application
{
  FTS.apps._.notes._.obsidian = {
    description = "Obsidian - Powerful knowledge base on top of a local folder of plain text Markdown files";

    homeManager = {pkgs, lib, ...}: let
      obsidian = pkgs.obsidian.overrideAttrs (prev: {
        postInstall = (prev.postInstall or "") + ''
          # Fix argv0 so Obsidian CLI recognizes itself as "obsidian"
          sed -i 's|^exec |exec -a obsidian |' $out/bin/obsidian
        '';
      });
    in {
      home.packages = [obsidian];
      home.activation.ensureObsidianConfigDir = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
        mkdir -p "$HOME/.config/obsidian"
      '';
    };

    nixos = {pkgs, ...}: let
      obsidian = pkgs.obsidian.overrideAttrs (prev: {
        postInstall = (prev.postInstall or "") + ''
          # Fix argv0 so Obsidian CLI recognizes itself as "obsidian"
          sed -i 's|^exec |exec -a obsidian |' $out/bin/obsidian
        '';
      });
    in {
      environment.systemPackages = [obsidian];
    };
  };
}
