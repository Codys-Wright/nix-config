{
  config,
  pkgs,
  lib,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.neovim;
in
{
  options.${namespace}.programs.neovim = {
    enable = mkBoolOpt false "${namespace}.programs.neovim.enable";
  };
  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # Use the standalone nvf flake
      package = inputs.self.packages.${pkgs.system}.neovim;

      extraPackages = with pkgs; [
        # LSPs
        luajitPackages.lua-lsp
        nil
        pyright

        # Formatter
        stylua
        ruff
        nixfmt-rfc-style

        # Languages and Compiler
        gcc
        python3
        nodejs
        cargo
        rustc
        cmake
        gnumake
        clang-tools

        ripgrep
        fzf
      ];
    };
  };
}
