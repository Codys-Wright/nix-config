{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.disko.url = "github:nix-community/disko";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  inputs.stylix.url = "github:danth/stylix";
  inputs.stylix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      ...
    }@inputs:
    {
      # VM-specific configuration with virtio disk
      nixosConfigurations.vm-nixos-facter = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
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
            home-manager.backupFileExtension = "bak-${builtins.substring 0 8 (builtins.hashString "sha256" (toString self.rev + toString inputs.nixpkgs.rev + toString inputs.nixpkgs.lastModified))}";
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
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vm-nixos-facter;
              };
            };
          };
        };
      };

      # Deploy-rs checks for deployment validation
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
    };
}
