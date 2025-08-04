{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.formatting;
in
{
  options.${namespace}.coding.editor.nvim.modules.formatting = with types; {
    enable = mkBoolOpt false "Enable nvim formatting modules";
  };

  config = mkIf cfg.enable {
    # Configure nvf formatting settings
    programs.nvf.settings.vim = {
      # Formatting with conform.nvim
      formatter.conform-nvim = {
        enable = true;
        setupOpts = {
          default_format_opts = {
            timeout_ms = 3000;
            async = false;
            quiet = false;
            lsp_format = "fallback";
          };
          formatters_by_ft = {
            lua = [ "stylua" ];
            fish = [ "fish_indent" ];
            sh = [ "shfmt" ];
          };
          formatters = {
            injected = { options = { ignore_errors = true; }; };
          };
          # Additional keybindings via setupOpts
          keys = [
            {
              "<leader>cF" = {
                function = "require('conform').format({ formatters = { 'injected' }, timeout_ms = 3000 })";
                mode = [ "n" "v" ];
                desc = "Format Injected Langs";
              };
            }
          ];
        };
      };
    };
  };
} 