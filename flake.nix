# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
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
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    controller-split = {
      url = "path:/run/media/Development/Tools/controller-split";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    daw = {
      url = "github:FastTrackStudios/daw";
      flake = false;
    };
    den.url = "github:denful/den";
    deploy-rs.url = "github:serokell/deploy-rs";
    dioxus-flake = {
      url = "github:FastTrackStudios/Dioxus-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    erosanix.url = "github:emmanuelrosa/erosanix";
    flake-aspects.url = "github:vic/flake-aspects";
    flake-file.url = "github:denful/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    fts-reaper-flake = {
      url = "github:FastTrackStudios/fts-reaper-flake";
      inputs = {
        daw.follows = "daw";
        reaper-flake.follows = "reaper-flake";
      };
    };
    ghidra-cli.url = "github:Codys-Wright/ghidra-cli/fix/ghidra-12-compat";
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent/v2026.7.20";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk/v0.22.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    inferno-control = {
      url = "git+https://codeberg.org/FastTrackStudios/inferno-control";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    loft = {
      url = "github:Codys-Wright/loft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    minegrub-theme.url = "github:Lxtharia/minegrub-theme";
    minegrub-world-sel-theme.url = "github:Lxtharia/minegrub-world-sel-theme";
    musnix.url = "github:musnix/musnix";
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-secrets.url = "git+ssh://git@github.com/Codys-Wright/nix-secrets.git?ref=main&shallow=1";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    nixpkgs-pipewire.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    reaper-flake = {
      url = "github:FastTrackStudios/reaper-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    wrappers.url = "github:lassulus/wrappers";
    xremap-flake.url = "github:xremap/nix-flake";
    zellij-nix.url = "github:a-kenji/zellij-nix";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };
}
