# CLI tools facet - All command-line tools
{
  FTS,
  ...
}:
{
  FTS.coding._.cli = {
    description = "All CLI development tools - atuin, btop, direnv, eza, fzf, just, sesh, yazi, zoxide";
    
    includes = [
      FTS.coding._.cli._.atuin
      FTS.coding._.cli._.btop
      FTS.coding._.cli._.direnv
      FTS.coding._.cli._.eza
      FTS.coding._.cli._.fzf
      FTS.coding._.cli._.just
      FTS.coding._.cli._.sesh
      FTS.coding._.cli._.yazi
      FTS.coding._.cli._.zoxide
    ];
    
    # NixOS system packages
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        gcc
        ripgrep
      ];
    };
  };
}

