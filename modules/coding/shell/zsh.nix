# Zsh shell aspect with custom configuration
{ ... }:
{
  den.aspects.zsh = {
    description = "Zsh shell with custom configuration and optimizations";

    homeManager = { config, pkgs, lib, ... }:
    let
      CLANG_BASE = "--build-base build_clang --install-base install_clang";
      BUILD_ARGS = "--symlink-install ${CLANG_BASE} --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON";
    in {
      programs.zsh = {
        enable = true;

        autosuggestion.enable = true;
        enableCompletion = true;
        historySubstringSearch.enable = true;
        syntaxHighlighting.enable = true;

        initContent = ''
          # Fix an issue with tmux.
          export KEYTIMEOUT=1

          # Use vim bindings.
          set -o vi

          export EDITOR="nvim"

          export NIX_LD=$(nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')

          export CC=clang
          export CXX=clang++

          # Colcon build configuration
          alias cb="colcon build ${BUILD_ARGS}"

          # History configuration
          export HISTSIZE=50000
          export SAVEHIST=10000
          export HISTFILE="$HOME/.zsh_history"
          setopt HIST_EXPIRE_DUPS_FIRST
          setopt HIST_IGNORE_DUPS
          setopt HIST_IGNORE_ALL_DUPS
          setopt HIST_IGNORE_SPACE
          setopt HIST_FIND_NO_DUPS
          setopt HIST_SAVE_NO_DUPS
          setopt HIST_BEEP

          # Directory navigation
          setopt AUTO_PUSHD
          setopt PUSHD_IGNORE_DUPS
          setopt PUSHD_SILENT

          # Completion improvements
          setopt COMPLETE_ALIASES
          setopt GLOB_COMPLETE
          setopt NO_CASE_GLOB

          # Better globbing
          setopt EXTENDED_GLOB

          # Prompt improvements
          setopt PROMPT_SUBST
        '';

        shellAliases = {
          # Editor aliases
          vim = "nvim";
          vi = "nvim";
          v = "nvim";

          # File listing aliases
          ls = "eza --icons=always --no-quotes";
          ll = "eza -l --icons=always --no-quotes";
          la = "eza -la --icons=always --no-quotes";
          tree = "eza --icons=always --tree --no-quotes";

          # Navigation aliases
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";

          # Git aliases (if not using dedicated git aspect)
          g = "git";
          gs = "git status";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gl = "git pull";

          # System aliases
          reload = "source ~/.zshrc";
          h = "history";
          c = "clear";

          # Directory aliases
          mkdir = "mkdir -pv";

          # Safety aliases
          rm = "rm -i";
          cp = "cp -i";
          mv = "mv -i";
        };

        # Additional zsh options for better experience
        history = {
          size = 50000;
          save = 10000;
          ignoreDups = true;
          ignoreSpace = true;
          expireDuplicatesFirst = true;
        };

        # Completion configuration
        completionInit = ''
          autoload -Uz compinit
          compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

          # Case insensitive completion
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

          # Completion menu
          zstyle ':completion:*' menu select

          # Better directory completion
          zstyle ':completion:*' special-dirs true

          # Process completion
          zstyle ':completion:*:processes' command 'ps -au$USER'
          zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;32'

          # SSH completion
          zstyle ':completion:*:ssh:*' hosts off
          zstyle ':completion:*:scp:*' hosts off
        '';

        plugins = [
          # Note: Prompt plugins (starship/powerlevel10k) should be added by their respective aspects
        ];
      };

      # Additional packages that complement zsh
      home.packages = with pkgs; [
        # Shell utilities
        zsh-completions
        nix-zsh-completions
      ];
    };
  };
}
