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

    # Add Frost overlay
    overlays = with inputs; [
      snowfall-frost.overlays.default
      (final: prev: {
        fabfilter-total-bundle = final.callPackage ./packages/fabfilter-total-bundle { };
      })
    ];

    # Deploy-rs configuration for managing deployments
    deploy = {
      nodes = {
        # VM deployment using nixos-anywhere
        vm = {
          hostname = "192.168.122.218"; # Update this IP when VM IP changes
          sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
          fastConnection = true;
          interactiveSudo = false; # root user, no sudo needed
          # Shorter timeouts to prevent hanging
          profiles = {
            system = {
              sshUser = "root";
              user = "root";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.vm;
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
      default = inputs.self.packages.${system}.docs;  # Default to docs package
    });

    # Apps for nix run support
    apps = forAllSystems (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in {
      default = inputs.self.apps.${system}.deploy;

      install = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "install" "exec bash ${./scripts/install.sh} \"$@\""}/bin/install";
      };
      
      deploy = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "deploy" "exec bash ${./scripts/deploy.sh} \"$@\""}/bin/deploy";
      };


    });

    # Deploy-rs checks for deployment validation
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
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
  };
}
