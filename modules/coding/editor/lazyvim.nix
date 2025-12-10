# LazyVim Neovim configuration
{
  FTS,
  inputs,
  pkgs,
  ...
}:
{
  flake-file.inputs.lazyvim.url = "github:Codys-Wright/lazyvim-nix";

  FTS.lazyvim = {
    description = "LazyVim Neovim distribution";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          ripgrep
          imagemagick
          tectonic
          ghostscript
          mermaid-cli
          fd
          luajitPackages.luarocks-nix
          alejandra
          sqlite
          tree-sitter
          statix
          biome
          nixfmt
          shfmt
          stylua
          typstyle
          terraform
          packer
        ];
      };

    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
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
          appName = "lazyvim"; # Install to ~/.config/lazyvim/ instead of ~/.config/nvim/

          # Optionally use existing lazyvim config directory from dots
          # If you want to use your existing config, uncomment this:
          # configFiles = "${config.home.homeDirectory}/.flake/users/cody/dots/config/lazyvim";

          installCoreDependencies = true;

          extras = {
            ai = {
              # avante.enable = true;
              # claudecode.enable = true;
              sidekick.enable = true;
            };
            coding = {
              blink.enable = true;
              mini_snippets.enable = true;
              mini_surround.enable = true;
              yanky.enable = true;
            };
            editor = {
              aerial.enable = true;
              dial.enable = true;
              harpoon2.enable = true;
              illuminate.enable = true;
              inc_rename.enable = true;
              mini_diff.enable = true;
              mini_files.enable = true;
              overseer.enable = true;
              refactoring.enable = true;
            };
            formatting = {
              biome.enable = true;
              prettier.enable = true;
            };
            lang = {
              nix.enable = true;
              rust = {
                enable = true;
                installDependencies = true;
                installRuntimeDependencies = false;
              };
              typescript.enable = true;
              tailwind.enable = true;
              typst.enable = true;
              nushell.enable = true;
              git.enable = true;
              cmake.enable = true;
              docker.enable = true;
              # sql.enable = true;
              terraform.enable = true;
              tex.enable = true;
              toml.enable = true;
              json.enable = true;
              yaml.enable = true;
              zig.enable = true;
            };
            linting = {
              eslint.enable = true;
              none_ls.enable = true;
            };
            test = {
              core.enable = true;
            };
            ui = {
              treesitter_context.enable = true;
            };
            util = {
              gh.enable = true;
              project.enable = true;
              mini_hipatterns.enable = true;
              rest.enable = true;
            };

          };

          # Additional packages (optional)
          extraPackages = with pkgs; [
            tree-sitter
            nixd # Nix LSP
            alejandra # Nix formatter
            bacon # rust background checker
            ripgrep

          ];

          # Tree-sitter parsers (nix and rust are auto-installed via lang extras)
          # python is auto-installed (core parser)
          treesitterParsers = with pkgs.tree-sitter-grammars; [
            tree-sitter-css
            tree-sitter-latex
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
