# Nvf-built Neovim configuration
{
  FTS, inputs, ... }:
{
  flake-file.inputs.nvf.url = "github:notashelf/nvf";
  flake-file.inputs.nvf.inputs.nixpkgs.follows = "nixpkgs";

  FTS.coding._.editors._.nvf = {
    description = "Neovim built with nvf configuration framework";

    homeManager = { pkgs, ... }:
    let
      customNeovim = inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [{
          config.vim = {
            viAlias = false;
            vimAlias = false;
          };
        }];
      };
    in
    {
      home.packages = [ customNeovim.neovim ];
    };
  };
}

