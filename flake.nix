{
  outputs = inputs: let
    randomBackupExt = "backup_${toString inputs.rand-nix.lib.rng.int}";
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;
      snowfall = {
        meta = {
          name = "nix-config";
          title = "Cody Wright's personal system fleet";
        };
        namespace = "FTS-FLEET";
      };
    };

    # Systems that can run tests:
    supportedSystems = [ "aarch64-linux" "i686-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

    # Function to generate a set based on supported systems:
    forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
  in
  lib.mkFlake {
    inherit inputs;
    src = ./.;


    channels-config = {
      allowUnfree = true;
      permittedInsecurePackages = [ ];
    };

    # Add Frost and Flake overlays
    overlays = with inputs; [
      snowfall-frost.overlays.default
      snowfall-flake.overlays.default
    ];



    # Deploy-rs configuration for managing deployments
    deploy = {
      nodes = {
     

        # Starcommand deployment
        starcommand = {
          hostname = "192.168.1.46";
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          fastConnection = true;
          interactiveSudo = false; # root user, no sudo needed
          profiles = {
            system = {
              sshUser = "root";
              user = "root";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.starcommand;
            };
          };
        };
      };
    };

    templates = import ./templates;

    # Development shell
    devShells = forAllSystems (system: {
      default = lib.mkShell {
        inherit inputs;
        src = ./.;
        shell = ./shells/default;
      };
    });

    # Documentation packages
    packages = forAllSystems (system: {
      docs = inputs.nixdoc.packages.${system}.nixdoc;
      frost = inputs.snowfall-frost.packages.${system}.frost;
      lyp = import ./packages/lyp { 
        pkgs = inputs.nixpkgs.legacyPackages.${system}; 
        inputs = inputs;
      };
      default = inputs.self.packages.${system}.docs;  # Default to docs package
    });



    # Deploy-rs checks for deployment validation
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    #macOs support
    darwin.url ="github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-frost = {
      url = "github:snowfallorg/frost";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional inputs from nixos-config
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    ags.url = "github:Aylur/ags";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple Color Emoji font
    apple-emoji-linux = {
      url = "github:samuelngs/apple-emoji-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nvf - Neovim configuration framework
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };



    # Documentation tools
    nixdoc = {
      url = "github:nix-community/nixdoc";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Random number generator for backup extensions
    rand-nix = {
      url = "github:figsoda/rand-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Astal for AGS shell
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };



    # Theme-related inputs
    whitesur-wallpapers = {
      url = "github:vinceliuice/whitesur-wallpapers";
      flake = false;
    };

    orchis-theme = {
      url = "github:vinceliuice/orchis-theme";
      flake = false;
    };

    # Additional theme assets
    wallpapers = {
      url = "github:orangci/walls-catppuccin-mocha";
      flake = false;
    };

    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # erosanix for mkWindowsApp functionality
    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Audio Haven - Local development (change to URL when ready for production)
    audiohaven = {
      url = "path:/home/cody/audiohaven";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Caelestia Shell - Modern Wayland shell with Qt6
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix search CLI tool
    nix-search-cli = {
      url = "github:peterldowns/nix-search-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix search TV - fuzzy search for Nix packages
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
