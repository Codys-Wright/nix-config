{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    # Supported systems
    supportedSystems = [ "aarch64-linux" "i686-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (system: {
      # Default configuration - balanced setup
      default =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./presets/default
          ];
        })
        .neovim;

      # Lazy configuration - full featured setup
      lazy =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./presets/lazy
          ];
        })
        .neovim;

      # Minimal configuration - lightweight setup
      minimal =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./presets/minimal
          ];
        })
        .neovim;
    });

    # Apps for nix run support
    apps = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "nvim" "exec ${inputs.self.packages.${system}.default}/bin/nvim \"$@\""}/bin/nvim";
      };

      lazy = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "nvim-lazy" "exec ${inputs.self.packages.${system}.lazy}/bin/nvim \"$@\""}/bin/nvim-lazy";
      };

      minimal = {
        type = "app";
        program = "${pkgs.writeShellScriptBin "nvim-minimal" "exec ${inputs.self.packages.${system}.minimal}/bin/nvim \"$@\""}/bin/nvim-minimal";
      };
    });
  };
}