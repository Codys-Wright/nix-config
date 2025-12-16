# LSP configuration and features
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{ lib, ... }:
{
  # LSP configuration
  lsp = {
    enable = true;
    formatOnSave = true;
    lightbulb.enable = true;
    trouble = {
      enable = true;
      # LazyVim-style trouble configuration
      setupOpts = {
        modes = {
          lsp = {
            win = {
              position = "right";
            };
          };
        };
      };
      # LazyVim-style trouble keymaps
      mappings = {
        documentDiagnostics = "<leader>xx"; # Diagnostics toggle
        workspaceDiagnostics = "<leader>xX"; # Buffer Diagnostics toggle
        symbols = "<leader>cs"; # Symbols toggle
        lspReferences = "<leader>cS"; # LSP references/definitions toggle
        locList = "<leader>xL"; # Location List toggle
        quickfix = "<leader>xQ"; # Quickfix List toggle
      };
    };
    lspSignature.enable = true;
  };

  # Enable trouble_lualine (shows trouble symbols in lualine)
  globals = {
    trouble_lualine = true;
  };

  # Inline diagnostics configuration (LazyVim-style)
  # This configures vim.diagnostic.config() to show inline virtual text
  diagnostics = {
    enable = true;
    config = {
      underline = true;
      update_in_insert = false;
      virtual_text = {
        spacing = 4;
        source = lib.generators.mkLuaInline "\"if_many\"";
        prefix = lib.generators.mkLuaInline "\"●\"";
        # Alternative: use icons based on severity
        # prefix = lib.generators.mkLuaInline ''
        #   function(diagnostic)
        #     local icons = {
        #       Error = "󰅚 ",
        #       Warn = "󰀪 ",
        #       Hint = "󰆈 ",
        #       Info = "󰋼 ",
        #     }
        #     for d, icon in pairs(icons) do
        #       if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
        #         return icon
        #       end
        #     end
        #     return "●"
        #   end
        # '';
      };
      severity_sort = true;
      signs = {
        text = lib.generators.mkLuaInline ''
          {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.HINT] = "󰆈 ",
            [vim.diagnostic.severity.INFO] = "󰋼 ",
          }
        '';
      };
    };
  };
}
