{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.linting;
in
{
  options.${namespace}.coding.editor.nvim.modules.linting = with types; {
    enable = mkBoolOpt false "Enable nvim linting modules";
  };

  config = mkIf cfg.enable {
    # Configure nvf linting settings
    programs.nvf.settings.vim = {
      # Linting with nvim-lint
      diagnostics.nvim-lint = {
        enable = true;
        lint_after_save = true;
        linters_by_ft = {
          fish = [ "fish" ];
          # "*" = [ "typos" ];  # Global linter for all filetypes
          # "_" = [ "fallback" ];  # Fallback linter for unconfigured filetypes
        };
        linters = {
          # Example of conditional linter (commented out)
          # selene = {
          #   condition = "function(ctx) return vim.fs.find({ 'selene.toml' }, { path = ctx.filename, upward = true })[1] end";
          # };
        };
      };
    };
  };
} 