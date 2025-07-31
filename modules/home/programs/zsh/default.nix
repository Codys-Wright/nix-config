{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.zsh;
  CLANG_BASE = "--build-base build_clang --install-base install_clang";
  BUILD_ARGS = "--symlink-install ${CLANG_BASE} --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON";
in
{
  options.${namespace}.programs.zsh = {
    enable = mkBoolOpt false "${namespace}.programs.zsh.enable";
  };

  config = mkIf cfg.enable {
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
          alias cb="colcon build ${BUILD_ARGS}"
      '';

      shellAliases = {
        vim = "nvim";
        vi = "nvim";
        v = "nvim";
        z = "cd";
        ls = "eza --icons=always --no-quotes";
        tree = "eza --icons=always --tree --no-quotes";
      };

      plugins = [ ];
    };
  };
}
