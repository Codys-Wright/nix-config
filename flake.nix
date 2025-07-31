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
    let
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
    in
    lib.mkFlake {
      inherit inputs;
      src = ./.;

      channels-config = {
        allowUnfree = true;
        permittedInsecurePackages = [ ];
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
                path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.vm;
              };
            };
          };
        };
      };

      templates = import ./templates;

      # Deploy-rs checks for deployment validation
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;
    };
}
