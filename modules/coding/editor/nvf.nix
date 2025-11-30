# Nvf-built Neovim configuration
{
  FTS, inputs, ... }:
{
  flake-file.inputs.nvf.url = "github:notashelf/nvf";
  flake-file.inputs.nvf.inputs.nixpkgs.follows = "nixpkgs";

  FTS.nvf = {
    description = "Neovim built with nvf configuration framework";

    homeManager = { pkgs, ... }:
    let
      # Build custom neovim package using nvf
      configModule = {
        config.vim = {
          viAlias = false;
          vimAlias = false;
        };
      };
      customNeovim = inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [ configModule ];
      };
      nvfNeovim = customNeovim.neovim;

      # Create wrapper script for nvf variant
      nvfWrapper = pkgs.writeShellApplication {
        name = "nvf";
        runtimeEnv = {
          NVIM_APPNAME = "nvf";
        };
        runtimeInputs = [ nvfNeovim ];
        text = ''exec nvim "$@"'';
      };
    in
    {
      home.packages = [
        nvfNeovim
        nvfWrapper
      ];
    };
  };
}

