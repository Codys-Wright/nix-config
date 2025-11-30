# AstroVim Neovim configuration wrapper
{
  FTS, ... }:
{
  FTS.astrovim = {
    description = "AstroVim Neovim distribution wrapper";

    homeManager = { pkgs, config, ... }:
    let
      # Create wrapper script for astrovim variant
      # Uses standard neovim from home-manager or nixpkgs
      astrovimWrapper = pkgs.writeShellApplication {
        name = "astrovim";
        runtimeEnv = {
          NVIM_APPNAME = "astrovim";
        };
        runtimeInputs = [
          # Use neovim from home-manager if available, otherwise from nixpkgs
          (config.programs.neovim.package or pkgs.neovim)
        ];
        text = ''exec nvim "$@"'';
      };
    in
    {
      home.packages = [
        astrovimWrapper
      ];
    };
  };
}

