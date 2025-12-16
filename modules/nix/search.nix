{
  lib,
  pkgs,
  FTS,
  ...
}: {
  FTS.nix._.search = {
    description = "Nix search tools (nix-search-tv) with ns alias";

    homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        nix-search-tv
        fzf # Required for the ns alias
      ];

      # Shell aliases for nix search
      # Note: Shell programs should be enabled elsewhere (e.g., via FTS.user._.shell or FTS.coding._.shells)
      programs.bash.shellAliases = {
        ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";
      };

      programs.zsh.shellAliases = {
        ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";
      };

      programs.fish.shellAliases = {
        ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";
      };
    };
  };
}
