{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.nvim.plugins.snacks;
in
{
  options.programs.nvim.plugins.snacks = {
    enable = mkEnableOption "snacks.nvim";
  };

  config = mkIf cfg.enable {
    programs.nvim = {
      plugins = {
        snacks = {
          enable = true;
          priority = 1000;
          lazy = false;
          setupOpts = {
            bigfile = { enabled = true };
            dashboard = { enabled = true };
            explorer = { enabled = true };
            indent = { enabled = true };
            input = { enabled = true };
            notifier = {
              enabled = true;
              timeout = 3000;
            };
            picker = { enabled = true };
            quickfile = { enabled = true };
            scope = { enabled = true };
            scroll = { enabled = true };
            statuscolumn = { enabled = true };
            words = { enabled = true };
            styles = {
              notification = {
                # wo = { wrap = true } -- Wrap notifications
              };
            };
          };
          keys = [
            # Top Pickers & Explorer
            { "<leader><space>" = "Smart Find Files"; function = "Snacks.picker.smart()"; }
            { "<leader>," = "Buffers"; function = "Snacks.picker.buffers()"; }
            { "<leader>/" = "Grep"; function = "Snacks.picker.grep()"; }
            { "<leader>:" = "Command History"; function = "Snacks.picker.command_history()"; }
            { "<leader>n" = "Notification History"; function = "Snacks.picker.notifications()"; }
            { "<leader>e" = "File Explorer"; function = "Snacks.explorer()"; }
            # find
            { "<leader>fb" = "Buffers"; function = "Snacks.picker.buffers()"; }
            { "<leader>fc" = "Find Config File"; function = "Snacks.picker.files({ cwd = vim.fn.stdpath('config') })"; }
            { "<leader>ff" = "Find Files"; function = "Snacks.picker.files()"; }
            { "<leader>fg" = "Find Git Files"; function = "Snacks.picker.git_files()"; }
            { "<leader>fp" = "Projects"; function = "Snacks.picker.projects()"; }
            { "<leader>fr" = "Recent"; function = "Snacks.picker.recent()"; }
            # git
            { "<leader>gb" = "Git Branches"; function = "Snacks.picker.git_branches()"; }
            { "<leader>gl" = "Git Log"; function = "Snacks.picker.git_log()"; }
            { "<leader>gL" = "Git Log Line"; function = "Snacks.picker.git_log_line()"; }
            { "<leader>gs" = "Git Status"; function = "Snacks.picker.git_status()"; }
            { "<leader>gS" = "Git Stash"; function = "Snacks.picker.git_stash()"; }
            { "<leader>gd" = "Git Diff (Hunks)"; function = "Snacks.picker.git_diff()"; }
            { "<leader>gf" = "Git Log File"; function = "Snacks.picker.git_log_file()"; }
            # Grep
            { "<leader>sb" = "Buffer Lines"; function = "Snacks.picker.lines()"; }
            { "<leader>sB" = "Grep Open Buffers"; function = "Snacks.picker.grep_buffers()"; }
            { "<leader>sg" = "Grep"; function = "Snacks.picker.grep()"; }
            { "<leader>sw" = "Visual selection or word"; function = "Snacks.picker.grep_word()"; mode = [ "n" "x" ]; }
            # search
            { "<leader>s\"" = "Registers"; function = "Snacks.picker.registers()"; }
            { "<leader>s/" = "Search History"; function = "Snacks.picker.search_history()"; }
            { "<leader>sa" = "Autocmds"; function = "Snacks.picker.autocmds()"; }
            { "<leader>sc" = "Command History"; function = "Snacks.picker.command_history()"; }
            { "<leader>sC" = "Commands"; function = "Snacks.picker.commands()"; }
            { "<leader>sd" = "Diagnostics"; function = "Snacks.picker.diagnostics()"; }
            { "<leader>sD" = "Buffer Diagnostics"; function = "Snacks.picker.diagnostics_buffer()"; }
            { "<leader>sh" = "Help Pages"; function = "Snacks.picker.help()"; }
            { "<leader>sH" = "Highlights"; function = "Snacks.picker.highlights()"; }
            { "<leader>si" = "Icons"; function = "Snacks.picker.icons()"; }
            { "<leader>sj" = "Jumps"; function = "Snacks.picker.jumps()"; }
            { "<leader>sk" = "Keymaps"; function = "Snacks.picker.keymaps()"; }
            { "<leader>sl" = "Location List"; function = "Snacks.picker.loclist()"; }
            { "<leader>sm" = "Marks"; function = "Snacks.picker.marks()"; }
            { "<leader>sM" = "Man Pages"; function = "Snacks.picker.man()"; }
            { "<leader>sp" = "Search for Plugin Spec"; function = "Snacks.picker.lazy()"; }
            { "<leader>sq" = "Quickfix List"; function = "Snacks.picker.qflist()"; }
            { "<leader>sR" = "Resume"; function = "Snacks.picker.resume()"; }
            { "<leader>su" = "Undo History"; function = "Snacks.picker.undo()"; }
            { "<leader>uC" = "Colorschemes"; function = "Snacks.picker.colorschemes()"; }
            # LSP
            { "gd" = "Goto Definition"; function = "Snacks.picker.lsp_definitions()"; }
            { "gD" = "Goto Declaration"; function = "Snacks.picker.lsp_declarations()"; }
            { "gr" = "References"; function = "Snacks.picker.lsp_references()"; nowait = true; }
            { "gI" = "Goto Implementation"; function = "Snacks.picker.lsp_implementations()"; }
            { "gy" = "Goto T[y]pe Definition"; function = "Snacks.picker.lsp_type_definitions()"; }
            { "<leader>ss" = "LSP Symbols"; function = "Snacks.picker.lsp_symbols()"; }
            { "<leader>sS" = "LSP Workspace Symbols"; function = "Snacks.picker.lsp_workspace_symbols()"; }
            # Other
            { "<leader>z" = "Toggle Zen Mode"; function = "Snacks.zen()"; }
            { "<leader>Z" = "Toggle Zoom"; function = "Snacks.zen.zoom()"; }
            { "<leader>." = "Toggle Scratch Buffer"; function = "Snacks.scratch()"; }
            { "<leader>S" = "Select Scratch Buffer"; function = "Snacks.scratch.select()"; }
            { "<leader>bd" = "Delete Buffer"; function = "Snacks.bufdelete()"; }
            { "<leader>cR" = "Rename File"; function = "Snacks.rename.rename_file()"; }
            { "<leader>gB" = "Git Browse"; function = "Snacks.gitbrowse()"; mode = [ "n" "v" ]; }
            { "<leader>gg" = "Lazygit"; function = "Snacks.lazygit()"; }
            { "<leader>un" = "Dismiss All Notifications"; function = "Snacks.notifier.hide()"; }
            { "<c-/>" = "Toggle Terminal"; function = "Snacks.terminal()"; }
            { "<c-_>" = "which_key_ignore"; function = "Snacks.terminal()"; }
            { "]]" = "Next Reference"; function = "Snacks.words.jump(vim.v.count1)"; mode = [ "n" "t" ]; }
            { "[[" = "Prev Reference"; function = "Snacks.words.jump(-vim.v.count1)"; mode = [ "n" "t" ]; }
            {
              "<leader>N" = "Neovim News";
              function = ''
                Snacks.win({
                  file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
                  width = 0.6,
                  height = 0.6,
                  wo = {
                    spell = false,
                    wrap = false,
                    signcolumn = "yes",
                    statuscolumn = " ",
                    conceallevel = 3,
                  },
                })
              '';
            }
          ];
          initLua = ''
            vim.api.nvim_create_autocmd("User", {
              pattern = "VeryLazy",
              callback = function()
                -- Setup some globals for debugging (lazy-loaded)
                _G.dd = function(...)
                  Snacks.debug.inspect(...)
                end
                _G.bt = function()
                  Snacks.debug.backtrace()
                end
                vim.print = _G.dd -- Override print to use snacks for `:=` command

                -- Create some toggle mappings
                Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                Snacks.toggle.diagnostics():map("<leader>ud")
                Snacks.toggle.line_number():map("<leader>ul")
                Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                Snacks.toggle.treesitter():map("<leader>uT")
                Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
                Snacks.toggle.inlay_hints():map("<leader>uh")
                Snacks.toggle.indent():map("<leader>ug")
                Snacks.toggle.dim():map("<leader>uD")
              end,
            })
          '';
        };
      };
    };
  };
} 