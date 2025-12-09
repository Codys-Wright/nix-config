# LazyVim Neovim configuration
{ FTS, inputs, pkgs, ... }:
{
  flake-file.inputs.lazyvim.url = "github:pfassina/lazyvim-nix/fix/treesitter-grammar-suffix";

  FTS.lazyvim = {
    description = "LazyVim Neovim distribution";

    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ripgrep
        imagemagick
        tectonic
        ghostscript
        mermaid-cli
        fd
        luajitPackages.luarocks-nix
        sqlite
      ];
    };

    homeManager = { config, pkgs, lib, ... }:
    let
      # Get the neovim package that lazyvim-nix uses
      neovimPackage = config.programs.neovim.package or pkgs.neovim;

      # Create wrapper script for lazyvim variant
      lazyvimWrapper = pkgs.writeShellApplication {
        name = "lazyvim";
        runtimeEnv = {
          NVIM_APPNAME = "lazyvim";
        };
        runtimeInputs = [ neovimPackage ];
        text = ''exec nvim "$@"'';
      };
    in
    {
      # Import lazyvim Home Manager module to configure lazyvim
      imports = [
        inputs.lazyvim.homeManagerModules.default
      ];

      programs.lazyvim = {
        enable = true;
        pluginSource = "latest";
        appName = "lazyvim";  # Install to ~/.config/lazyvim/ instead of ~/.config/nvim/

        # Optionally use existing lazyvim config directory from dots
        # If you want to use your existing config, uncomment this:
        # configFiles = "${config.home.homeDirectory}/.flake/users/cody/dots/config/lazyvim";

        installCoreDependencies = true;

        extras = {
          lang = {
            nix.enable = true;
            rust = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = false;
            };
          };
        };

        # Additional packages (optional)
        extraPackages = with pkgs; [
          nixd       # Nix LSP
          alejandra  # Nix formatter
          bacon      # rust background checker
          ripgrep
        ];

        # Tree-sitter parsers (nix and rust are auto-installed via lang extras)
        # python is auto-installed (core parser)
        treesitterParsers = with pkgs.tree-sitter-grammars; [
          tree-sitter-css
          tree-sitter-latex
          tree-sitter-norg
          tree-sitter-scss
          tree-sitter-svelte
          tree-sitter-typst
          tree-sitter-vue
        ];
      };

      # Install the lazyvim wrapper executable
      home.packages = [ lazyvimWrapper ];
    };


  };
}
