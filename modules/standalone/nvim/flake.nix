{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    lib = inputs.snowfall-lib.mkLib {
      inherit inputs;
      src = ./.;
      snowfall = {
        meta = {
          name = "neovim-standalone";
          title = "Standalone Neovim Configuration";
        };
        namespace = "NVIM";
      };
    };
  in
  lib.mkFlake {
    inherit inputs;
    src = ./.;

    # Supported systems
    supportedSystems = [ "aarch64-linux" "i686-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];

    # Packages for each supported system
    packages = lib.mkPackages {
      # Default configuration - balanced setup
      default = { pkgs, ... }: {
        neovim = (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ./presets/default ];
        }).neovim;
      };

      # Lazy configuration - full featured setup
      lazy = { pkgs, ... }: {
        neovim = (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ./presets/lazy ];
        }).neovim;
      };

      # Minimal configuration - lightweight setup
      minimal = { pkgs, ... }: {
        neovim = (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ./presets/minimal ];
        }).neovim;
      };
    };

    # Apps for nix run support
    apps = lib.mkApps {
      default = { pkgs, ... }: {
        type = "app";
        program = "${pkgs.writeShellScriptBin "nvim" "exec ${inputs.self.packages.${pkgs.system}.default.neovim}/bin/nvim \"$@\""}/bin/nvim";
      };

      lazy = { pkgs, ... }: {
        type = "app";
        program = "${pkgs.writeShellScriptBin "nvim-lazy" "exec ${inputs.self.packages.${pkgs.system}.lazy.neovim}/bin/nvim \"$@\""}/bin/nvim-lazy";
      };

      minimal = { pkgs, ... }: {
        type = "app";
        program = "${pkgs.writeShellScriptBin "nvim-minimal" "exec ${inputs.self.packages.${pkgs.system}.minimal.neovim}/bin/nvim \"$@\""}/bin/nvim-minimal";
      };
    };
  };
}