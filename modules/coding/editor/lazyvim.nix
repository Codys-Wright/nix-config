# LazyVim Neovim configuration wrapper
{ FTS, inputs, pkgs, ... }:
{
  flake-file.inputs.lazyvim.url = "github:pfassina/lazyvim-nix";

  FTS.lazyvim = {
    description = "LazyVim Neovim distribution wrapper";

    homeManager = { config, pkgs, lib, ... }: {
        imports = [
                inputs.lazyvim.homeManagerModules.default
        ];

        programs.lazyvim = {
        enable = true;
         pluginSource = "latest";

         extras = {
           lang.nix.enable = true;
           lang.python = {
             enable = true;
             installDependencies = true;        # Install ruff
               installRuntimeDependencies = true; # Install python3
           };
           lang.go = {
             enable = true;
             installDependencies = true;        # Install gopls, gofumpt, etc.
               installRuntimeDependencies = true; # Install go compiler
           };
         };
# Additional packages (optional)
  extraPackages = with pkgs; [
    nixd       # Nix LSP
    alejandra  # Nix formatter
  ];

 # Only needed for languages not covered by LazyVim
  treesitterParsers = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
    wgsl      # WebGPU Shading Language
    templ     # Go templ files
  ];



        };
    };
  };
}

