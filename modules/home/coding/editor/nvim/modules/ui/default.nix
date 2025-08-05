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
      # Statusline
      statusline.lualine = {
        enable = true;
        theme = lib.mkForce "auto";
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
        disabledFiletypes = [ "dashboard" "alpha" "ministarter" "snacks_dashboard" ];
        ignoreFocus = [ "NvimTree" ];
        setupOpts = {
          options = {
            theme = "auto";
            globalstatus = true;
            disabled_filetypes = { statusline = [ "dashboard" "alpha" "ministarter" "snacks_dashboard" ]; };
          };
          sections = {
            lualine_a = [ "mode" ];
            lualine_b = [ "branch" ];
            lualine_c = [
              "root_dir"
              {
                diagnostics = {
                  symbols = {
                    error = "󰅚";
                    warn = "󰀪";
                    info = "󰋼";
                    hint = "󰌵";
                  };
                };
              }
              {
                filetype = {
                  icon_only = true;
                  separator = "";
                  padding = { left = 1; right = 0; };
                };
              }
              "pretty_path"
            ];
            lualine_x = [
              {
                function = "Snacks.profiler.status";
              }
              {
                function = "require('noice').api.status.command.get";
                cond = "package.loaded['noice'] and require('noice').api.status.command.has()";
                color = "function() return { fg = Snacks.util.color('Statement') } end";
              }
              {
                function = "require('noice').api.status.mode.get";
                cond = "package.loaded['noice'] and require('noice').api.status.mode.has()";
                color = "function() return { fg = Snacks.util.color('Constant') } end";
              }
              {
                function = "function() return '  ' .. require('dap').status() end";
                cond = "package.loaded['dap'] and require('dap').status() ~= ''";
                color = "function() return { fg = Snacks.util.color('Debug') } end";
              }
              {
                diff = {
                  symbols = {
                    added = "󰐕";
                    modified = "󰆓";
                    removed = "󰍴";
                  };
                  source = "function() local gitsigns = vim.b.gitsigns_status_dict if gitsigns then return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed } end end";
                };
              }
            ];
            lualine_y = [
              {
                progress = {
                  separator = " ";
                  padding = { left = 1; right = 0; };
                };
              }
              {
                location = {
                  padding = { left = 0; right = 1; };
                };
              }
            ];
            lualine_z = [
              {
                function = "function() return ' ' .. os.date('%R') end";
              }
            ];
          };
          extensions = lib.mkForce [ "neo-tree" "lazy" "fzf" ];
        };
      };

      # Visual enhancements
      mini = {
        colors.enable = true;
        icons.enable = true;
        indentscope.enable = true;
        trailspace.enable = true;
        icons.setupOpts = {
          file = {
            ".keep" = { glyph = "󰊢"; hl = "MiniIconsGrey"; };
            "devcontainer.json" = { glyph = ""; hl = "MiniIconsAzure"; };
          };
          filetype = {
            dotenv = { glyph = " "; hl = "MiniIconsYellow"; };
          };
        };
      };
      
      # Noice UI enhancement
      ui.noice = {
        enable = true;
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
      
      # Noice keybindings
      keymaps = [
        {
          key = "<S-Enter>";
          mode = [ "c" ];
          action = "function() require('noice').redirect(vim.fn.getcmdline()) end";
          desc = "Redirect Cmdline";
          lua = true;
        }
        {
          key = "<leader>snl";
          mode = [ "n" ];
          action = "function() require('noice').cmd('last') end";
          desc = "Noice Last Message";
          lua = true;
        }
        {
          key = "<leader>snh";
          mode = [ "n" ];
          action = "function() require('noice').cmd('history') end";
          desc = "Noice History";
          lua = true;
        }
        {
          key = "<leader>sna";
          mode = [ "n" ];
          action = "function() require('noice').cmd('all') end";
          desc = "Noice All";
          lua = true;
        }
        {
          key = "<leader>snd";
          mode = [ "n" ];
          action = "function() require('noice').cmd('dismiss') end";
          desc = "Dismiss All";
          lua = true;
        }
        {
          key = "<leader>snt";
          mode = [ "n" ];
          action = "function() require('noice').cmd('pick') end";
          desc = "Noice Picker (Telescope/FzfLua)";
          lua = true;
        }
        {
          key = "<c-f>";
          mode = [ "i" "n" "s" ];
          action = "function() if not require('noice.lsp').scroll(4) then return '<c-f>' end end";
          desc = "Scroll Forward";
          lua = true;
          expr = true;
          silent = true;
        }
        {
          key = "<c-b>";
          mode = [ "i" "n" "s" ];
          action = "function() if not require('noice.lsp').scroll(-4) then return '<c-b>' end end";
          desc = "Scroll Backward";
          lua = true;
          expr = true;
          silent = true;
        }
      ];
    };
  };
} 