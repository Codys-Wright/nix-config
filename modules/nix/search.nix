let
  my.nix._.search = {
    nixos = search-system-packages;
    darwin = search-system-packages;
    inherit homeManager;
  };

  search-system-packages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nix-search-tv
        fzf # Required for the ns alias
      ];
    };

  nsAlias = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history --preview-window=up:50%";

  homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nix-search-tv
        fzf # Required for the ns alias
      ];

      # Shell aliases for nix search
      # Note: Shell programs should be enabled elsewhere (e.g., via FTS.user._.shell or FTS.coding._.shells)
      programs.bash.shellAliases.ns = nsAlias;
      programs.zsh.shellAliases.ns = nsAlias;
      programs.fish.shellAliases.ns = nsAlias;
    };
in
{
  FTS.nix._.search = {
    description = "Nix search tools (nix-search-tv) with ns alias";
  }
  // my.nix._.search;
}
