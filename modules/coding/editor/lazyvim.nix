# LazyVim Neovim configuration wrapper
{
  FTS, ... }:
{
  FTS.lazyvim = {
    description = "LazyVim Neovim distribution wrapper";

    homeManager = { pkgs, config, ... }:
    let
      # Create wrapper script for lazyvim variant
      # Uses standard neovim from home-manager or nixpkgs
      lazyvimWrapper = pkgs.writeShellApplication {
        name = "lazyvim";
        runtimeEnv = {
          NVIM_APPNAME = "lazyvim";
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
        lazyvimWrapper
      ];
    };
  };
}

