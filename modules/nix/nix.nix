{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
  flake-file.inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  # Enable unfree packages for darwin/nixos/home-manager modules
  flake.modules.darwin.nixpkgs.config.allowUnfree = true;
  flake.modules.nixos.nixpkgs.config.allowUnfree = true;
  flake.modules.homeManager.nixpkgs.config.allowUnfree = true;

  # Overlays for accessing stable and unstable nixpkgs
  flake.modules.nixos.nixpkgs.overlays = [
    # Add stable packages as pkgs.stable
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })

    # Add unstable packages as pkgs.unstable
    # Note: inputs.nixpkgs is already nixpkgs-unstable
    (final: prev: {
      unstable = import inputs.nixpkgs {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];

  flake.modules.darwin.nixpkgs.overlays = [
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })

    (final: prev: {
      unstable = import inputs.nixpkgs {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];

  flake.modules.homeManager.nixpkgs.overlays = [
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })

    (final: prev: {
      unstable = import inputs.nixpkgs {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];

  # Enable nix-command and flakes experimental features
  flake.modules.nixos.nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  flake.modules.darwin.nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
