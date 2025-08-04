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
          enable = true; # Enable by default when module is imported
          priority = 1000;
          lazy = false;
          setupOpts = {
            bigfile = { enabled = true; };
            dashboard = { enabled = true; };
            explorer = { enabled = true; };
            indent = { enabled = true; };
            input = { enabled = true; };
            notifier = {
              enabled = true;
              timeout = 3000;
            };
            picker = { enabled = true; };
            quickfile = { enabled = true; };
            scope = { enabled = true; };
            scroll = { enabled = true; };
            statuscolumn = { enabled = true; };
            words = { enabled = true; };
            styles = {
              notification = {
                # wo = { wrap = true } -- Wrap notifications
              };
            };
            keys = [
              # Top Pickers & Explorer
              {
                "<leader><space>" = {
                  function = "Snacks.picker.smart()";
                  desc = "Smart Find Files";
                };
                "<leader>," = {
                  function = "Snacks.picker.buffers()";
                  desc = "Buffers";
                };
                "<leader>/" = {
                  function = "Snacks.picker.grep()";
                  desc = "Grep";
                };
                "<leader>:" = {
                  function = "Snacks.picker.command_history()";
                  desc = "Command History";
                };
                "<leader>n" = {
                  function = "Snacks.picker.notifications()";
                  desc = "Notification History";
                };
                "<leader>e" = {
                  function = "Snacks.explorer()";
                  desc = "File Explorer";
                };
                # find
                "<leader>fb" = {
                  function = "Snacks.picker.buffers()";
                  desc = "Buffers";
                };
                "<leader>fc" = {
                  function = "Snacks.picker.files({ cwd = vim.fn.stdpath('config') })";
                  desc = "Find Config File";
                };
                "<leader>ff" = {
                  function = "Snacks.picker.files()";
                  desc = "Find Files";
                };
                "<leader>fg" = {
                  function = "Snacks.picker.git_files()";
                  desc = "Find Git Files";
                };
                "<leader>fp" = {
                  function = "Snacks.picker.projects()";
                  desc = "Projects";
                };
                "<leader>fr" = {
                  function = "Snacks.picker.recent()";
                  desc = "Recent";
                };
                # git
                "<leader>gb" = {
                  function = "Snacks.picker.git_branches()";
                  desc = "Git Branches";
                };
                "<leader>gl" = {
                  function = "Snacks.picker.git_log()";
                  desc = "Git Log";
                };
                "<leader>gL" = {
                  function = "Snacks.picker.git_log_line()";
                  desc = "Git Log Line";
                };
                "<leader>gs" = {
                  function = "Snacks.picker.git_status()";
                  desc = "Git Status";
                };
                "<leader>gS" = {
                  function = "Snacks.picker.git_stash()";
                  desc = "Git Stash";
                };
                "<leader>gd" = {
                  function = "Snacks.picker.git_diff()";
                  desc = "Git Diff (Hunks)";
                };
                "<leader>gf" = {
                  function = "Snacks.picker.git_log_file()";
                  desc = "Git Log File";
                };
                # Grep
                "<leader>sb" = {
                  function = "Snacks.picker.lines()";
                  desc = "Buffer Lines";
                };
                "<leader>sB" = {
                  function = "Snacks.picker.grep_buffers()";
                  desc = "Grep Open Buffers";
                };
                "<leader>sg" = {
                  function = "Snacks.picker.grep()";
                  desc = "Grep";
                };
                "<leader>sw" = {
                  function = "Snacks.picker.grep_word()";
                  desc = "Visual selection or word";
                  mode = [ "n" "x" ];
                };
                # search
                "<leader>s\"" = {
                  function = "Snacks.picker.registers()";
                  desc = "Registers";
                };
                "<leader>s/" = {
                  function = "Snacks.picker.search_history()";
                  desc = "Search History";
                };
                "<leader>sa" = {
                  function = "Snacks.picker.autocmds()";
                  desc = "Autocmds";
                };
                "<leader>sc" = {
                  function = "Snacks.picker.command_history()";
                  desc = "Command History";
                };
                "<leader>sC" = {
                  function = "Snacks.picker.commands()";
                  desc = "Commands";
                };
                "<leader>sd" = {
                  function = "Snacks.picker.diagnostics()";
                  desc = "Diagnostics";
                };
                "<leader>sD" = {
                  function = "Snacks.picker.diagnostics_buffer()";
                  desc = "Buffer Diagnostics";
                };
                "<leader>sh" = {
                  function = "Snacks.picker.help()";
                  desc = "Help Pages";
                };
                "<leader>sH" = {
                  function = "Snacks.picker.highlights()";
                  desc = "Highlights";
                };
                "<leader>si" = {
                  function = "Snacks.picker.icons()";
                  desc = "Icons";
                };
                "<leader>sj" = {
                  function = "Snacks.picker.jumps()";
                  desc = "Jumps";
                };
                "<leader>sk" = {
                  function = "Snacks.picker.keymaps()";
                  desc = "Keymaps";
                };
                "<leader>sl" = {
                  function = "Snacks.picker.loclist()";
                  desc = "Location List";
                };
                "<leader>sm" = {
                  function = "Snacks.picker.marks()";
                  desc = "Marks";
                };
                "<leader>sM" = {
                  function = "Snacks.picker.man()";
                  desc = "Man Pages";
                };
                "<leader>sp" = {
                  function = "Snacks.picker.lazy()";
                  desc = "Search for Plugin Spec";
                };
                "<leader>sq" = {
                  function = "Snacks.picker.qflist()";
                  desc = "Quickfix List";
                };
                "<leader>sR" = {
                  function = "Snacks.picker.resume()";
                  desc = "Resume";
                };
                "<leader>su" = {
                  function = "Snacks.picker.undo()";
                  desc = "Undo History";
                };
                "<leader>uC" = {
                  function = "Snacks.picker.colorschemes()";
                  desc = "Colorschemes";
                };
                # LSP
                "gd" = {
                  function = "Snacks.picker.lsp_definitions()";
                  desc = "Goto Definition";
                };
                "gD" = {
                  function = "Snacks.picker.lsp_declarations()";
                  desc = "Goto Declaration";
                };
                "gr" = {
                  function = "Snacks.picker.lsp_references()";
                  desc = "References";
                  nowait = true;
                };
                "gI" = {
                  function = "Snacks.picker.lsp_implementations()";
                  desc = "Goto Implementation";
                };
                "gy" = {
                  function = "Snacks.picker.lsp_type_definitions()";
                  desc = "Goto T[y]pe Definition";
                };
                "<leader>ss" = {
                  function = "Snacks.picker.lsp_symbols()";
                  desc = "LSP Symbols";
                };
                "<leader>sS" = {
                  function = "Snacks.picker.lsp_workspace_symbols()";
                  desc = "LSP Workspace Symbols";
                };
                # Other
                "<leader>z" = {
                  function = "Snacks.zen()";
                  desc = "Toggle Zen Mode";
                };
                "<leader>Z" = {
                  function = "Snacks.zen.zoom()";
                  desc = "Toggle Zoom";
                };
                "<leader>." = {
                  function = "Snacks.scratch()";
                  desc = "Toggle Scratch Buffer";
                };
                "<leader>S" = {
                  function = "Snacks.scratch.select()";
                  desc = "Select Scratch Buffer";
                };
                "<leader>bd" = {
                  function = "Snacks.bufdelete()";
                  desc = "Delete Buffer";
                };
                "<leader>cR" = {
                  function = "Snacks.rename.rename_file()";
                  desc = "Rename File";
                };
                "<leader>gB" = {
                  function = "Snacks.gitbrowse()";
                  desc = "Git Browse";
                  mode = [ "n" "v" ];
                };
                "<leader>gg" = {
                  function = "Snacks.lazygit()";
                  desc = "Lazygit";
                };
                "<leader>un" = {
                  function = "Snacks.notifier.hide()";
                  desc = "Dismiss All Notifications";
                };
                "<c-/>" = {
                  function = "Snacks.terminal()";
                  desc = "Toggle Terminal";
                };
                "<c-_>" = {
                  function = "Snacks.terminal()";
                  desc = "which_key_ignore";
                };
                "]]" = {
                  function = "Snacks.words.jump(vim.v.count1)";
                  desc = "Next Reference";
                  mode = [ "n" "t" ];
                };
                "[[" = {
                  function = "Snacks.words.jump(-vim.v.count1)";
                  desc = "Prev Reference";
                  mode = [ "n" "t" ];
                };
                "<leader>N" = {
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
                  desc = "Neovim News";
                };
              }
            ];
        };
      };
    };
  };
} 