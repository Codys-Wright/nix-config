{
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
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      # Configure Snowfall Lib
      snowfall = {
        # Tell Snowfall Lib to look in the `./nix/` directory for your Nix files
        root = ./nix;

        # Choose a namespace to use for your flake's packages, library, and overlays
        namespace = "nix-config";

        # Add flake metadata
        meta = {
          # A slug to use in documentation when displaying things like file paths
          name = "nix-config";

          # A title to show for your flake
          title = "Nix Config";
        };
      };

      # Keep all existing configurations
      systems = {
        x86_64-linux = {
          hosts = {
            vm-nixos-facter = {
              modules = [
                inputs.disko.nixosModules.disko
                ./configuration.nix
                inputs.stylix.nixosModules.stylix
                inputs.home-manager.nixosModules.home-manager
                inputs.nixos-facter-modules.nixosModules.facter
                { disko.devices.disk.disk1.device = "/dev/vda"; }
                {
                  config.facter.reportPath =
                    if builtins.pathExists ./facter.json then
                      ./facter.json
                    else
                      throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";
                }
                {
                  # Configure Home Manager to handle file conflicts with unique identifier
                  home-manager.backupFileExtension = "bak-${builtins.substring 0 8 (builtins.hashString "sha256" (toString inputs.self.rev + toString inputs.nixpkgs.rev + toString inputs.nixpkgs.lastModified))}";
                }
                {
                  home-manager.users.cody = { config, pkgs, ... }: {
                    # Home Manager configuration
                    home = {
                      username = "cody";
                      homeDirectory = "/home/cody";
                      stateVersion = "24.05";
                    };

                    # Programs
                    programs = {
                      home-manager.enable = true;
                    };

                    imports = [
                    ];

                    # Enable stylix in Home Manager (will inherit from system)
                    stylix = {
                      autoEnable = true;

                      targets = {
                        kitty = {
                          enable = true;
                        };
                      };
                    };
                  };
                }
              ];
            };
          };
        };
      };

      # Deploy-rs configuration for managing deployments
      deploy = {
        nodes = {
          # VM deployment using nixos-anywhere
          vm = {
            hostname = "192.168.122.217"; # Your VM IP
            sshOpts = [ "-o" "StrictHostKeyChecking=no" ];
            fastConnection = true;
            interactiveSudo = false; # root user, no sudo needed
            profiles = {
              system = {
                sshUser = "root";
                user = "root";
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.vm-nixos-facter;
              };
            };
          };
        };
      };

      # Deploy-rs checks for deployment validation
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;
    };
}
