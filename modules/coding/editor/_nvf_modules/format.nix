# Formatters configuration (conform.nvim - LazyVim-style)
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Conform.nvim configuration (LazyVim-style)
  # LazyVim uses conform.nvim as the primary formatter
  formatter = {
    conform-nvim = {
      enable = true;
      setupOpts = {
        # LazyVim-style default format options
        default_format_opts = {
          timeout_ms = 3000;
          async = false; # not recommended to change
          quiet = false; # not recommended to change
          lsp_format = "fallback"; # not recommended to change
        };
        # LazyVim-style formatters by filetype
        formatters_by_ft = {
          lua = ["stylua"];
          fish = ["fish_indent"];
          sh = ["shfmt"];
        };
        # Custom formatters and overrides
        formatters = {
          injected = {
            options = {
              ignore_errors = true;
            };
          };
        };
      };
    };
  };

  # Add LazyVim-style keymap for formatting injected languages
  keymaps = [
    {
      key = "<leader>cF";
      mode = ["n" "x"];
      action = ''
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end
      '';
      lua = true;
      desc = "Format Injected Langs";
    }
  ];

  # Note: which-key automatically discovers keymaps with desc attributes,
  # so we don't need to manually register them here.
}
