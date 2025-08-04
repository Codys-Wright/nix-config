{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.ui;
in
{
  options.${namespace}.coding.editor.nvim.modules.ui = with types; {
    enable = mkBoolOpt false "Enable nvim UI modules";
  };

  config = mkIf cfg.enable {
    # Configure nvf UI settings
    programs.nvf.settings.vim = {
      # Theme configuration
      theme = {
        enable = true;
        name = "tokyonight";
        style = "moon";
      };

      # Statusline
      statusline.lualine = {
        enable = true;
        theme = "auto";
        globalStatus = true;
        icons.enable = true;
        alwaysDivideMiddle = true;
        componentSeparator = {
          left = "";
          right = "";
        };
        sectionSeparator = {
          left = "";
          right = "";
        };
        refresh = {
          statusline = 1000;
          tabline = 1000;
          winbar = 1000;
        };
        disabledFiletypes = [ "alpha" ];
        ignoreFocus = [ "NvimTree" ];
        # Active sections (A | B | C       X | Y | Z)
        activeSection = {
          a = [ "mode" ];
          b = [ "branch" "diff" "diagnostics" ];
          c = [ "filename" ];
          x = [ "encoding" "fileformat" "filetype" ];
          y = [ "progress" ];
          z = [ "location" ];
        };
        # Inactive sections
        inactiveSection = {
          a = [ ];
          b = [ ];
          c = [ "filename" ];
          x = [ "location" ];
          y = [ ];
          z = [ ];
        };
        # Extra sections for customization
        extraActiveSection = {
          a = [ ];
          b = [ ];
          c = [ ];
          x = [ ];
          y = [ ];
          z = [ ];
        };
        extraInactiveSection = {
          a = [ ];
          b = [ ];
          c = [ ];
          x = [ ];
          y = [ ];
          z = [ ];
        };
      };

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
    };
  };
} 
