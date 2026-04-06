# CLI tools facet - All command-line tools
{ fleet, ... }:
{
  fleet.coding._.cli = {
    description = "All CLI development tools - atuin, btop, direnv, eza, fzf, just, sesh, yazi, zoxide";

    includes = [
      fleet.coding._.cli._.atuin
      fleet.coding._.cli._.btop
      fleet.coding._.cli._.direnv
      fleet.coding._.cli._.eza
      fleet.coding._.cli._.fzf
      fleet.coding._.cli._.just
      fleet.coding._.cli._.sesh
      fleet.coding._.cli._.yazi
      fleet.coding._.cli._.zoxide
    ];

    # NixOS system packages
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          gcc
          ripgrep
          just
          openssl
          openssl.dev
          openssl_3
          dioxus-cli
          bat
        ];
      };

    # Darwin system packages
    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          ripgrep
          bat
          openssl
          openssl.dev
          dioxus-cli
          # gcc is available via Xcode Command Line Tools on macOS
        ];
      };
  };
}
