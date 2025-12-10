# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  description = "A flake for Cody's Entire Computing World";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        (inputs.import-tree ./modules)
        (inputs.import-tree ./hosts)
        (inputs.import-tree ./users)
      ];
    };

  inputs = {
    SPC.url = "github:vic/SPC";
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    colmena = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:zhaofengli/colmena";
    };
    darwin = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-darwin/nix-darwin";
    };
    den.url = "github:vic/den";
    deploy-rs = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:serokell/deploy-rs";
    };
    disko = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/disko";
    };
    doom-emacs = {
      flake = false;
      url = "github:doomemacs/doomemacs";
    };
    flake-aspects.url = "github:vic/flake-aspects";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      url = "github:hercules-ci/flake-parts";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    import-tree.url = "github:vic/import-tree";
    lazyvim.url = "github:Codys-Wright/lazyvim-nix";
    minegrub-theme.url = "github:Lxtharia/minegrub-theme";
    minegrub-world-sel-theme.url = "github:Lxtharia/minegrub-world-sel-theme";
    minesddm = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Davi-S/sddm-theme-minesddm";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-anywhere = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixos-anywhere";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-generators = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixos-generators";
    };
    nixos-wsl = {
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "nixpkgs-stable";
      };
      url = "github:nix-community/nixos-wsl";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nvf = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:notashelf/nvf";
    };
    rust-overlay = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:oxalica/rust-overlay";
    };
    sops-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:Mic92/sops-nix";
    };
    stylix.url = "github:danth/stylix";
    systems.url = "github:nix-systems/default";
    zen-browser = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:0xc000022070/zen-browser-flake";
    };
  };

}
