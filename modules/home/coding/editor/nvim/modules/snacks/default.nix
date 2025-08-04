{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.snacks;
in
{
  options.${namespace}.coding.editor.nvim.modules.snacks = with types; {
    enable = mkBoolOpt false "Enable nvim snacks modules";
  };

  config = mkIf cfg.enable {
    # Configure nvf snacks settings
    programs.nvf.settings.vim = {
      # Snacks-nvim for QoL plugins
      utility.snacks-nvim = {
        enable = true;
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
      };

      # Snacks keybindings
      binds.whichKey.register = {
        # Top Pickers & Explorer
        "<leader><space>" = "Smart Find Files";
        "<leader>," = "Buffers";
        "<leader>/" = "Grep";
        "<leader>:" = "Command History";
        "<leader>n" = "Notification History";
        "<leader>e" = "File Explorer";
        
        # Find
        "<leader>fb" = "Buffers";
        "<leader>fc" = "Find Config File";
        "<leader>ff" = "Find Files";
        "<leader>fg" = "Find Git Files";
        "<leader>fp" = "Projects";
        "<leader>fr" = "Recent";
        
        # Git
        "<leader>gb" = "Git Branches";
        "<leader>gl" = "Git Log";
        "<leader>gL" = "Git Log Line";
        "<leader>gs" = "Git Status";
        "<leader>gS" = "Git Stash";
        "<leader>gd" = "Git Diff (Hunks)";
        "<leader>gf" = "Git Log File";
        
        # Grep
        "<leader>sb" = "Buffer Lines";
        "<leader>sB" = "Grep Open Buffers";
        "<leader>sg" = "Grep";
        "<leader>sw" = "Visual selection or word";
        
        # Search
        "<leader>s\"" = "Registers";
        "<leader>s/" = "Search History";
        "<leader>sa" = "Autocmds";
        "<leader>sc" = "Command History";
        "<leader>sC" = "Commands";
        "<leader>sd" = "Diagnostics";
        "<leader>sD" = "Buffer Diagnostics";
        "<leader>sh" = "Help Pages";
        "<leader>sH" = "Highlights";
        "<leader>si" = "Icons";
        "<leader>sj" = "Jumps";
        "<leader>sk" = "Keymaps";
        "<leader>sl" = "Location List";
        "<leader>sm" = "Marks";
        "<leader>sM" = "Man Pages";
        "<leader>sp" = "Search for Plugin Spec";
        "<leader>sq" = "Quickfix List";
        "<leader>sR" = "Resume";
        "<leader>su" = "Undo History";
        
        # UI
        "<leader>uC" = "Colorschemes";
        "<leader>ss" = "LSP Symbols";
        "<leader>sS" = "LSP Workspace Symbols";
        "<leader>z" = "Toggle Zen Mode";
        "<leader>Z" = "Toggle Zoom";
        "<leader>." = "Toggle Scratch Buffer";
        "<leader>S" = "Select Scratch Buffer";
        "<leader>bd" = "Delete Buffer";
        "<leader>cR" = "Rename File";
        "<leader>gB" = "Git Browse";
        "<leader>gg" = "Lazygit";
        "<leader>un" = "Dismiss All Notifications";
        "<leader>N" = "Neovim News";
        
        # LSP
        "gd" = "Goto Definition";
        "gD" = "Goto Declaration";
        "gr" = "References";
        "gI" = "Goto Implementation";
        "gy" = "Goto T[y]pe Definition";
        
        # Other
        "]]" = "Next Reference";
        "[[" = "Prev Reference";
        "<c-/>" = "Toggle Terminal";
        "<c-_>" = "which_key_ignore";
      };
    };
  };
} 