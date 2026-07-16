# Noice configuration (LazyVim-style) and its init autocmd
# Split from ../ui.nix — returns config.vim settings directly
{ lib, ... }:
{
  # Noice configuration (LazyVim-style)
  ui = {
    noice = {
      enable = true;
      # LazyVim-style noice configuration
      setupOpts = {
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
        };
        routes = [
          {
            filter = {
              event = "msg_show";
              any = [
                { find = "%d+L, %d+B"; }
                { find = "; after #%d+"; }
                { find = "; before #%d+"; }
              ];
            };
            view = "mini";
          }
        ];
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
        };
      };
    };
  };

  # Noice init function (clear messages when filetype is lazy)
  luaConfigRC.noice-init = ''
    -- LazyVim-style noice init: clear messages when filetype is lazy
    -- This prevents noice from showing messages from before it was enabled
    -- when Lazy is installing plugins
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "lazy",
      callback = function()
        vim.cmd([[messages clear]])
      end,
    })
  '';
}
