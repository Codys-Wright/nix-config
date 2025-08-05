{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.snacks;
in
{
  options.${namespace}.coding.editor.nvim.modules.snacks = with types; {
    enable = mkBoolOpt false "Enable nvim snacks picker module";
  };

  config = mkIf cfg.enable {
    # Add required packages for snacks.nvim picker
    home.packages = with pkgs; [
      # Git for git-related picker functions
      git
      # ImageMagick for image conversion
      imagemagick
      # Ghostscript for PDF processing
      ghostscript
      # Tectonic for LaTeX processing
      tectonic
      # Mermaid CLI for diagrams
      mermaid-cli
      # SQLite for database support
      sqlite
    ];

    # Configure nvf snacks settings
    programs.nvf.settings.vim = {
      # Enable lazy loading
      lazy.enable = true;

      # Snacks-nvim as lazy plugin - picker only
      utility.snacks-nvim = {
        enable = true;
       
        setupOpts = {
          bigfile = { enabled = true; };
          picker = { enabled = true; };
          explorer = { enabled = true; };
          dashboard = { enabled = false; };
          indent = { enabled = true; };
          input = { enabled = true; };
          notifier = {
            enabled = true;
            timeout = 3000;
          };
          quickfile = { enabled = true; };
          scope = { enabled = true; };
          scroll = { enabled = true; };
          statuscolumn = { enabled = true; };
          words = { enabled = true; };
          styles = {
            notification = {
              # wo = { wrap = true } # Wrap notifications
            };
          };
        };
      };

      # Alpha dashboard configuration
      dashboard.alpha = {
        enable = true;
        theme = "dashboard";
        opts = {
          startup = true;
          layout = [
            {
              type = "padding";
              val = 1;
            }
            {
              type = "text";
              val = [
                "██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z"
                "██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    "
                "██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       "
                "██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         "
                "███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           "
                "╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           "
              ];
              opts = {
                position = "center";
                hl = "AlphaHeader";
              };
            }
            {
              type = "padding";
              val = 2;
            }
            {
              type = "group";
                             val = [
                 {
                   type = "text";
                   val = "Quick Actions";
                   opts = {
                     hl = "AlphaButtons";
                     shrink_margin = false;
                     position = "center";
                   };
                 }
                 {
                   type = "padding";
                   val = 1;
                 }
                 {
                   type = "group";
                   val = [
                     {
                       type = "button";
                       val = "󰈞 Find File";
                       on_press = {
                         raw = "lua Snacks.picker.files()";
                       };
                       opts = {
                         hl = "AlphaButtons";
                         position = "center";
                         shortcut = "f";
                         cursor = 2;
                         width = 40;
                         align_shortcut = "right";
                         shrink_margin = false;
                       };
                     }
                     {
                       type = "button";
                       val = "󰈙 New File";
                       on_press = {
                         raw = "ene | startinsert";
                       };
                       opts = {
                         hl = "AlphaButtons";
                         position = "center";
                         shortcut = "n";
                         cursor = 2;
                         width = 40;
                         align_shortcut = "right";
                         shrink_margin = false;
                       };
                     }
                     {
                       type = "button";
                       val = "󰍉 Find Text";
                       on_press = {
                         raw = "lua Snacks.picker.grep()";
                       };
                       opts = {
                         hl = "AlphaButtons";
                         position = "center";
                         shortcut = "g";
                         cursor = 2;
                         width = 40;
                         align_shortcut = "right";
                         shrink_margin = false;
                       };
                     }
                     {
                       type = "button";
                       val = "󰙯 Recent Files";
                       on_press = {
                         raw = "lua Snacks.picker.recent()";
                       };
                       opts = {
                         hl = "AlphaButtons";
                         position = "center";
                         shortcut = "r";
                         cursor = 2;
                         width = 40;
                         align_shortcut = "right";
                         shrink_margin = false;
                       };
                     }
                     {
                       type = "button";
                       val = "󰐣 Config";
                       on_press = {
                         raw = "lua Snacks.picker.files({cwd = vim.fn.stdpath('config')})";
                       };
                       opts = {
                         hl = "AlphaButtons";
                         position = "center";
                         shortcut = "c";
                         cursor = 2;
                         width = 40;
                         align_shortcut = "right";
                         shrink_margin = false;
                       };
                     }
                     {
                       type = "button";
                       val = "󰐦 Quit";
                       on_press = {
                         raw = "qa";
                       };
                       opts = {
                         hl = "AlphaButtons";
                         position = "center";
                         shortcut = "q";
                         cursor = 2;
                         width = 40;
                         align_shortcut = "right";
                         shrink_margin = false;
                       };
                     }
                   ];
                 }
               ];
            }
            {
              type = "padding";
              val = 1;
            }
            {
              type = "text";
              val = "Welcome to Neovim!";
              opts = {
                position = "center";
                hl = "AlphaFooter";
              };
            }
          ];
        };
      };

      # Snacks picker keybindings
      keymaps = [
        # Alpha Dashboard
        {
          key = "<leader>d";
          mode = [ "n" ];
          action = "function() require('alpha').start() end";
          desc = "Alpha Dashboard";
          lua = true;
        }
        # Top Pickers & Explorer
        {
          key = "<leader><space>";
          mode = [ "n" ];
          action = "function() Snacks.picker.smart() end";
          desc = "Smart Find Files";
          lua = true;
        }
        {
          key = "<leader>,";
          mode = [ "n" ];
          action = "function() Snacks.picker.buffers() end";
          desc = "Buffers";
          lua = true;
        }
        {
          key = "<leader>/";
          mode = [ "n" ];
          action = "function() Snacks.picker.grep() end";
          desc = "Grep";
          lua = true;
        }
        {
          key = "<leader>:";
          mode = [ "n" ];
          action = "function() Snacks.picker.command_history() end";
          desc = "Command History";
          lua = true;
        }
        {
          key = "<leader>n";
          mode = [ "n" ];
          action = "function() Snacks.picker.notifications() end";
          desc = "Notification History";
          lua = true;
        }
        {
          key = "<leader>e";
          mode = [ "n" ];
          action = "function() Snacks.explorer() end";
          desc = "File Explorer";
          lua = true;
        }
        # Find
        {
          key = "<leader>fb";
          mode = [ "n" ];
          action = "function() Snacks.picker.buffers() end";
          desc = "Buffers";
          lua = true;
        }
        {
          key = "<leader>fc";
          mode = [ "n" ];
          action = "function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end";
          desc = "Find Config File";
          lua = true;
        }
        {
          key = "<leader>ff";
          mode = [ "n" ];
          action = "function() Snacks.picker.files() end";
          desc = "Find Files";
          lua = true;
        }
        {
          key = "<leader>fg";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_files() end";
          desc = "Find Git Files";
          lua = true;
        }
        {
          key = "<leader>fp";
          mode = [ "n" ];
          action = "function() Snacks.picker.projects() end";
          desc = "Projects";
          lua = true;
        }
        {
          key = "<leader>fr";
          mode = [ "n" ];
          action = "function() Snacks.picker.recent() end";
          desc = "Recent";
          lua = true;
        }
        # Git
        {
          key = "<leader>gb";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_branches() end";
          desc = "Git Branches";
          lua = true;
        }
        {
          key = "<leader>gl";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_log() end";
          desc = "Git Log";
          lua = true;
        }
        {
          key = "<leader>gL";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_log_line() end";
          desc = "Git Log Line";
          lua = true;
        }
        {
          key = "<leader>gs";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_status() end";
          desc = "Git Status";
          lua = true;
        }
        {
          key = "<leader>gS";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_stash() end";
          desc = "Git Stash";
          lua = true;
        }
        {
          key = "<leader>gd";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_diff() end";
          desc = "Git Diff (Hunks)";
          lua = true;
        }
        {
          key = "<leader>gf";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_log_file() end";
          desc = "Git Log File";
          lua = true;
        }
        # Grep
        {
          key = "<leader>sb";
          mode = [ "n" ];
          action = "function() Snacks.picker.lines() end";
          desc = "Buffer Lines";
          lua = true;
        }
        {
          key = "<leader>sB";
          mode = [ "n" ];
          action = "function() Snacks.picker.grep_buffers() end";
          desc = "Grep Open Buffers";
          lua = true;
        }
        {
          key = "<leader>sg";
          mode = [ "n" ];
          action = "function() Snacks.picker.grep() end";
          desc = "Grep";
          lua = true;
        }
        {
          key = "<leader>sw";
          mode = [ "n" "x" ];
          action = "function() Snacks.picker.grep_word() end";
          desc = "Visual selection or word";
          lua = true;
        }
        # Search
        {
          key = "<leader>s\"";
          mode = [ "n" ];
          action = "function() Snacks.picker.registers() end";
          desc = "Registers";
          lua = true;
        }
        {
          key = "<leader>s/";
          mode = [ "n" ];
          action = "function() Snacks.picker.search_history() end";
          desc = "Search History";
          lua = true;
        }
        {
          key = "<leader>sa";
          mode = [ "n" ];
          action = "function() Snacks.picker.autocmds() end";
          desc = "Autocmds";
          lua = true;
        }
        {
          key = "<leader>sc";
          mode = [ "n" ];
          action = "function() Snacks.picker.command_history() end";
          desc = "Command History";
          lua = true;
        }
        {
          key = "<leader>sC";
          mode = [ "n" ];
          action = "function() Snacks.picker.commands() end";
          desc = "Commands";
          lua = true;
        }
        {
          key = "<leader>sd";
          mode = [ "n" ];
          action = "function() Snacks.picker.diagnostics() end";
          desc = "Diagnostics";
          lua = true;
        }
        {
          key = "<leader>sD";
          mode = [ "n" ];
          action = "function() Snacks.picker.diagnostics_buffer() end";
          desc = "Buffer Diagnostics";
          lua = true;
        }
        {
          key = "<leader>sh";
          mode = [ "n" ];
          action = "function() Snacks.picker.help() end";
          desc = "Help Pages";
          lua = true;
        }
        {
          key = "<leader>sH";
          mode = [ "n" ];
          action = "function() Snacks.picker.highlights() end";
          desc = "Highlights";
          lua = true;
        }
        {
          key = "<leader>si";
          mode = [ "n" ];
          action = "function() Snacks.picker.icons() end";
          desc = "Icons";
          lua = true;
        }
        {
          key = "<leader>sj";
          mode = [ "n" ];
          action = "function() Snacks.picker.jumps() end";
          desc = "Jumps";
          lua = true;
        }
        {
          key = "<leader>sk";
          mode = [ "n" ];
          action = "function() Snacks.picker.keymaps() end";
          desc = "Keymaps";
          lua = true;
        }
        {
          key = "<leader>sl";
          mode = [ "n" ];
          action = "function() Snacks.picker.loclist() end";
          desc = "Location List";
          lua = true;
        }
        {
          key = "<leader>sm";
          mode = [ "n" ];
          action = "function() Snacks.picker.marks() end";
          desc = "Marks";
          lua = true;
        }
        {
          key = "<leader>sM";
          mode = [ "n" ];
          action = "function() Snacks.picker.man() end";
          desc = "Man Pages";
          lua = true;
        }
        {
          key = "<leader>sp";
          mode = [ "n" ];
          action = "function() Snacks.picker.lazy() end";
          desc = "Search for Plugin Spec";
          lua = true;
        }
        {
          key = "<leader>sq";
          mode = [ "n" ];
          action = "function() Snacks.picker.qflist() end";
          desc = "Quickfix List";
          lua = true;
        }
        {
          key = "<leader>sR";
          mode = [ "n" ];
          action = "function() Snacks.picker.resume() end";
          desc = "Resume";
          lua = true;
        }
        {
          key = "<leader>su";
          mode = [ "n" ];
          action = "function() Snacks.picker.undo() end";
          desc = "Undo History";
          lua = true;
        }
        {
          key = "<leader>uC";
          mode = [ "n" ];
          action = "function() Snacks.picker.colorschemes() end";
          desc = "Colorschemes";
          lua = true;
        }
        # LSP
        {
          key = "gd";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_definitions() end";
          desc = "Goto Definition";
          lua = true;
        }
        {
          key = "gD";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_declarations() end";
          desc = "Goto Declaration";
          lua = true;
        }
        {
          key = "gr";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_references() end";
          desc = "References";
          lua = true;
          nowait = true;
        }
        {
          key = "gI";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_implementations() end";
          desc = "Goto Implementation";
          lua = true;
        }
        {
          key = "gy";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_type_definitions() end";
          desc = "Goto T[y]pe Definition";
          lua = true;
        }
        {
          key = "<leader>ss";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_symbols() end";
          desc = "LSP Symbols";
          lua = true;
        }
        {
          key = "<leader>sS";
          mode = [ "n" ];
          action = "function() Snacks.picker.lsp_workspace_symbols() end";
          desc = "LSP Workspace Symbols";
          lua = true;
        }
        # Other
        {
          key = "<leader>z";
          mode = [ "n" ];
          action = "function() Snacks.zen() end";
          desc = "Toggle Zen Mode";
          lua = true;
        }
        {
          key = "<leader>Z";
          mode = [ "n" ];
          action = "function() Snacks.zen.zoom() end";
          desc = "Toggle Zoom";
          lua = true;
        }
        {
          key = "<leader>.";
          mode = [ "n" ];
          action = "function() Snacks.scratch() end";
          desc = "Toggle Scratch Buffer";
          lua = true;
        }
        {
          key = "<leader>S";
          mode = [ "n" ];
          action = "function() Snacks.scratch.select() end";
          desc = "Select Scratch Buffer";
          lua = true;
        }
        {
          key = "<leader>bd";
          mode = [ "n" ];
          action = "function() Snacks.bufdelete() end";
          desc = "Delete Buffer";
          lua = true;
        }
        {
          key = "<leader>cR";
          mode = [ "n" ];
          action = "function() Snacks.rename.rename_file() end";
          desc = "Rename File";
          lua = true;
        }
        {
          key = "<leader>gB";
          mode = [ "n" "v" ];
          action = "function() Snacks.gitbrowse() end";
          desc = "Git Browse";
          lua = true;
        }
        {
          key = "<leader>gg";
          mode = [ "n" ];
          action = "function() Snacks.lazygit() end";
          desc = "Lazygit";
          lua = true;
        }
        {
          key = "<leader>un";
          mode = [ "n" ];
          action = "function() Snacks.notifier.hide() end";
          desc = "Dismiss All Notifications";
          lua = true;
        }
        {
          key = "<c-/>";
          mode = [ "n" ];
          action = "function() Snacks.terminal() end";
          desc = "Toggle Terminal";
          lua = true;
        }
        {
          key = "<c-_>";
          mode = [ "n" ];
          action = "function() Snacks.terminal() end";
          desc = "which_key_ignore";
          lua = true;
        }
        {
          key = "]]";
          mode = [ "n" "t" ];
          action = "function() Snacks.words.jump(vim.v.count1) end";
          desc = "Next Reference";
          lua = true;
        }
        {
          key = "[[";
          mode = [ "n" "t" ];
          action = "function() Snacks.words.jump(-vim.v.count1) end";
          desc = "Prev Reference";
          lua = true;
        }
        {
          key = "<leader>N";
          mode = [ "n" ];
          action = "function() Snacks.win({file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1], width = 0.6, height = 0.6, wo = {spell = false, wrap = false, signcolumn = 'yes', statuscolumn = ' ', conceallevel = 3}}) end";
          desc = "Neovim News";
          lua = true;
        }
      ];
      
      # Snacks autocommands for toggle mappings
      autocmds = [
        {
          event = [ "User" ];
          pattern = [ "VeryLazy" ];
          callback = lib.mkLuaInline ''
            function()
              _G.dd = function(...)
                Snacks.debug.inspect(...)
              end
              _G.bt = function()
                Snacks.debug.backtrace()
              end
              vim.print = _G.dd
              
              Snacks.toggle.option("spell", {name = "Spelling"}):map("<leader>us")
              Snacks.toggle.option("wrap", {name = "Wrap"}):map("<leader>uw")
              Snacks.toggle.option("relativenumber", {name = "Relative Number"}):map("<leader>uL")
              Snacks.toggle.diagnostics():map("<leader>ud")
              Snacks.toggle.line_number():map("<leader>ul")
              Snacks.toggle.option("conceallevel", {off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2}):map("<leader>uc")
              Snacks.toggle.treesitter():map("<leader>uT")
              Snacks.toggle.option("background", {off = "light", on = "dark", name = "Dark Background"}):map("<leader>ub")
              Snacks.toggle.inlay_hints():map("<leader>uh")
              Snacks.toggle.indent():map("<leader>ug")
              Snacks.toggle.dim():map("<leader>uD")
            end
          '';
          desc = "Snacks toggle mappings initialization";
        }
      ];
    };
  };
} 