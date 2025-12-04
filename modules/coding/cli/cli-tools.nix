# CLI tools meta-aspect - includes all CLI tool modules
{
  FTS, ... }:
{
  FTS.cli-tools = {
    description = "All CLI tools - includes direnv, btop, atuin, eza, fzf, zoxide, yazi, sesh, and just";

    includes = [
      FTS.direnv
      FTS.btop
      FTS.atuin
      FTS.eza
      FTS.fzf
      FTS.zoxide
      FTS.yazi
      FTS.sesh
      FTS.just
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

