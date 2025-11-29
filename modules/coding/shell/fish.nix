# Fish shell aspect with custom configuration
{
  FTS, ... }:
{
  FTS.fish = {
    description = "Fish shell with custom configuration and optimizations";

    homeManager = { config, pkgs, lib, ... }: {
      programs.fish = {
        enable = true;

        interactiveShellInit = ''
          # Fix an issue with tmux.
          set -g fish_escape_delay_ms 10

          # Set vim key bindings
          fish_vi_key_bindings

          # Set editor
          set -gx EDITOR nvim

          # Set NIX_LD for dynamic linking
          set -gx NIX_LD (nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')

          # Compiler settings
          set -gx CC clang
          set -gx CXX clang++

          # History configuration
          set -g fish_history_max_count 50000

          # Disable greeting
          set -g fish_greeting

          # Enable directory abbreviations
          abbr -a .. 'cd ..'
          abbr -a ... 'cd ../..'
          abbr -a .... 'cd ../../..'
          abbr -a ..... 'cd ../../../..'

          # Editor abbreviations
          abbr -a vim nvim
          abbr -a vi nvim
          abbr -a v nvim

          # File listing abbreviations
          abbr -a ls 'eza --icons=always --no-quotes'
          abbr -a ll 'eza -l --icons=always --no-quotes'
          abbr -a la 'eza -la --icons=always --no-quotes'
          abbr -a tree 'eza --icons=always --tree --no-quotes'

          # Git abbreviations
          abbr -a g git
          abbr -a gs 'git status'
          abbr -a ga 'git add'
          abbr -a gc 'git commit'
          abbr -a gp 'git push'
          abbr -a gl 'git pull'

          # System abbreviations
          abbr -a reload 'source ~/.config/fish/config.fish'
          abbr -a h 'history'
          abbr -a c clear

          # Directory abbreviations
          abbr -a mkdir 'mkdir -pv'

          # Safety abbreviations
          abbr -a rm 'rm -i'
          abbr -a cp 'cp -i'
          abbr -a mv 'mv -i'
        '';

        functions = {
          # Custom functions can go here
        };

        plugins = [
          # Add fish plugins as needed
        ];
      };

      # Additional packages that complement fish
      home.packages = with pkgs; [
        # Shell utilities
        fishPlugins.done
        fishPlugins.fzf-fish
        fishPlugins.forgit
      ];
    };
  };
}
