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
            {
              config.vim = {
                # Enable custom theming options
                theme.enable = true;

                # Enable Treesitter
                treesitter.enable = true;

                # Other options will go here. Refer to the config
                # reference in Appendix B of the nvf manual.
                # ...
              };
            }
          ];
        })
        .neovim;

      # Lazy configuration - full featured setup
      lazy =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            {
              config.vim = {
                # Enable custom theming options
                theme.enable = true;

                # Enable Treesitter
                treesitter.enable = true;

                # Other options will go here. Refer to the config
                # reference in Appendix B of the nvf manual.
                # ...
              };
            }
          ];
        })
        .neovim;

      # Minimal configuration - lightweight setup
      minimal =
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            {
              config.vim = {
                # Enable custom theming options
                theme.enable = true;

                # Enable Treesitter
                treesitter.enable = true;

                # Other options will go here. Refer to the config
                # reference in Appendix B of the nvf manual.
                # ...
              };
            }
          ];
        })
        .neovim;
    };
  };
}