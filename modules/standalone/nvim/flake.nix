{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf.url = "github:notashelf/nvf";
  };

  outputs = {nixpkgs, ...} @ inputs: {
    packages.x86_64-linux = {
      # Default configuration - balanced setup
      default =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/default
          ];
        })
        .neovim;

      # Lazy configuration - full featured setup
      lazy =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/lazy
          ];
        })
        .neovim;

      # Minimal configuration - lightweight setup
      minimal =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./modules/minimal
          ];
        })
        .neovim;
    };
  };
}