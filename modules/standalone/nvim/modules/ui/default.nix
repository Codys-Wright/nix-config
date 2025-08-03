{
  config.vim = {
    # Theme configuration
    theme = {
      enable = true;
      name = "tokyonight";
      style = "moon";
    };

    # Statusline
    statusline.lualine.enable = true;

    # Visual enhancements
    mini = {
      colors.enable = true;
      icons.enable = true;
      indentscope.enable = true;
      trailspace.enable = true;
    };

    # Animations
    mini.animate.enable = true;

    # Tabline
    mini.tabline.enable = true;

    # Bufferline for enhanced buffer management
    tabline.nvimBufferline = {
      enable = true;
      setupOpts = {
        options = {
          close_command = "Snacks.bufdelete";
          right_mouse_command = "Snacks.bufdelete";
          diagnostics = "nvim_lsp";
          always_show_bufferline = false;
          # diagnostics_indicator = "function(_, _, diag) local icons = LazyVim.config.icons.diagnostics local ret = (diag.error and icons.Error .. diag.error .. ' ' or '') .. (diag.warning and icons.Warn .. diag.warning or '') return vim.trim(ret) end";
          offsets = [
            {
              filetype = "neo-tree";
              text = "Neo-tree";
              highlight = "Directory";
              text_align = "left";
            }
            {
              filetype = "snacks_layout_box";
            }
          ];
          # get_element_icon = "function(opts) return LazyVim.config.icons.ft[opts.filetype] end";
        };
      };
    };

    # Bufferline keybindings
    binds.whichKey.register = {
      "<leader>bp" = "Toggle Pin";
      "<leader>bP" = "Delete Non-Pinned Buffers";
      "<leader>br" = "Delete Buffers to the Right";
      "<leader>bl" = "Delete Buffers to the Left";
      "<S-h>" = "Prev Buffer";
      "<S-l>" = "Next Buffer";
      "[b" = "Prev Buffer";
      "]b" = "Next Buffer";
      "[B" = "Move buffer prev";
      "]B" = "Move buffer next";
    };

    # Bufferline keybindings - handled by bufferline plugin itself
  };
} 
