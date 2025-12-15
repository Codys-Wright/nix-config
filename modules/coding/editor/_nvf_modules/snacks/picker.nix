# Snacks.nvim picker configuration
# Returns config.vim settings directly
# Takes lib as parameter for mkLuaInline
{lib, ...}: {
  # Configure snacks picker
  utility.snacks-nvim.setupOpts = {
    picker = {
      win = {
        input = {
          # Keys structure: Using mkLuaInline for complex nested structure
          # The action name must be the first element in a list format
          keys = lib.generators.mkLuaInline ''
            {
              ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" } },
            }
          '';
        };
      };
      actions = {
        # toggle_cwd action function
        toggle_cwd = lib.generators.mkLuaInline ''
          function(p)
            local root = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h"))
            local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local current = p:cwd()
            p:set_cwd(current == root and cwd or root)
            p:find()
          end
        '';
      };
    };
  };

  # All snacks picker keybinds (following LazyVim snacks.nvim example)
  # Note: When lua = true, action must be a function string, not a direct call
  keymaps = [
    # Explorer keybinds
    {
      key = "<leader>e";
      mode = "n";
      action = "function() require('snacks').explorer() end";
      lua = true;
      desc = "File Explorer";
    }
    {
      key = "<leader>E";
      mode = "n";
      action = "function() require('snacks').explorer({ cwd = vim.fn.getcwd() }) end";
      lua = true;
      desc = "File Explorer (cwd)";
    }
    # Top Pickers
    {
      key = "<leader><space>";
      mode = "n";
      action = "function() require('snacks').picker.smart() end";
      lua = true;
      desc = "Smart Find Files";
    }
    {
      key = "<leader>,";
      mode = "n";
      action = "function() require('snacks').picker.buffers() end";
      lua = true;
      desc = "Buffers";
    }
    {
      key = "<leader>/";
      mode = "n";
      action = "function() require('snacks').picker.grep() end";
      lua = true;
      desc = "Grep";
    }
    {
      key = "<leader>:";
      mode = "n";
      action = "function() require('snacks').picker.command_history() end";
      lua = true;
      desc = "Command History";
    }
    {
      key = "<leader>n";
      mode = "n";
      action = "function() if Snacks.config.picker and Snacks.config.picker.enabled then require('snacks').picker.notifications() else require('snacks').notifier.show_history() end end";
      lua = true;
      desc = "Notification History";
    }
    # find
    {
      key = "<leader>fb";
      mode = "n";
      action = "function() require('snacks').picker.buffers() end";
      lua = true;
      desc = "Buffers";
    }
    {
      key = "<leader>fc";
      mode = "n";
      action = "function() require('snacks').picker.files({ cwd = vim.fn.stdpath('config') }) end";
      lua = true;
      desc = "Find Config File";
    }
    {
      key = "<leader>ff";
      mode = "n";
      action = "function() require('snacks').picker.files() end";
      lua = true;
      desc = "Find Files";
    }
    {
      key = "<leader>fg";
      mode = "n";
      action = "function() require('snacks').picker.git_files() end";
      lua = true;
      desc = "Find Git Files";
    }
    {
      key = "<leader>fp";
      mode = "n";
      action = "function() require('snacks').picker.projects() end";
      lua = true;
      desc = "Projects";
    }
    {
      key = "<leader>fr";
      mode = "n";
      action = "function() require('snacks').picker.recent() end";
      lua = true;
      desc = "Recent";
    }
    # git
    {
      key = "<leader>gb";
      mode = "n";
      action = "function() require('snacks').picker.git_branches() end";
      lua = true;
      desc = "Git Branches";
    }
    {
      key = "<leader>gl";
      mode = "n";
      action = "function() require('snacks').picker.git_log() end";
      lua = true;
      desc = "Git Log";
    }
    {
      key = "<leader>gL";
      mode = "n";
      action = "function() require('snacks').picker.git_log_line() end";
      lua = true;
      desc = "Git Log Line";
    }
    {
      key = "<leader>gs";
      mode = "n";
      action = "function() require('snacks').picker.git_status() end";
      lua = true;
      desc = "Git Status";
    }
    {
      key = "<leader>gS";
      mode = "n";
      action = "function() require('snacks').picker.git_stash() end";
      lua = true;
      desc = "Git Stash";
    }
    {
      key = "<leader>gd";
      mode = "n";
      action = "function() require('snacks').picker.git_diff() end";
      lua = true;
      desc = "Git Diff (Hunks)";
    }
    {
      key = "<leader>gf";
      mode = "n";
      action = "function() require('snacks').picker.git_log_file() end";
      lua = true;
      desc = "Git Log File";
    }
    # gh
    {
      key = "<leader>gi";
      mode = "n";
      action = "function() require('snacks').picker.gh_issue() end";
      lua = true;
      desc = "GitHub Issues (open)";
    }
    {
      key = "<leader>gI";
      mode = "n";
      action = "function() require('snacks').picker.gh_issue({ state = 'all' }) end";
      lua = true;
      desc = "GitHub Issues (all)";
    }
    {
      key = "<leader>gp";
      mode = "n";
      action = "function() require('snacks').picker.gh_pr() end";
      lua = true;
      desc = "GitHub Pull Requests (open)";
    }
    {
      key = "<leader>gP";
      mode = "n";
      action = "function() require('snacks').picker.gh_pr({ state = 'all' }) end";
      lua = true;
      desc = "GitHub Pull Requests (all)";
    }
    # Grep
    {
      key = "<leader>sb";
      mode = "n";
      action = "function() require('snacks').picker.lines() end";
      lua = true;
      desc = "Buffer Lines";
    }
    {
      key = "<leader>sB";
      mode = "n";
      action = "function() require('snacks').picker.grep_buffers() end";
      lua = true;
      desc = "Grep Open Buffers";
    }
    {
      key = "<leader>sg";
      mode = "n";
      action = "function() require('snacks').picker.grep() end";
      lua = true;
      desc = "Grep";
    }
    {
      key = "<leader>sw";
      mode = ["n" "x"];
      action = "function() require('snacks').picker.grep_word() end";
      lua = true;
      desc = "Visual selection or word";
    }
    # search
    {
      key = "<leader>s\"";
      mode = "n";
      action = "function() require('snacks').picker.registers() end";
      lua = true;
      desc = "Registers";
    }
    {
      key = "<leader>s/";
      mode = "n";
      action = "function() require('snacks').picker.search_history() end";
      lua = true;
      desc = "Search History";
    }
    {
      key = "<leader>sa";
      mode = "n";
      action = "function() require('snacks').picker.autocmds() end";
      lua = true;
      desc = "Autocmds";
    }
    {
      key = "<leader>sc";
      mode = "n";
      action = "function() require('snacks').picker.command_history() end";
      lua = true;
      desc = "Command History";
    }
    {
      key = "<leader>sC";
      mode = "n";
      action = "function() require('snacks').picker.commands() end";
      lua = true;
      desc = "Commands";
    }
    {
      key = "<leader>sd";
      mode = "n";
      action = "function() require('snacks').picker.diagnostics() end";
      lua = true;
      desc = "Diagnostics";
    }
    {
      key = "<leader>sD";
      mode = "n";
      action = "function() require('snacks').picker.diagnostics_buffer() end";
      lua = true;
      desc = "Buffer Diagnostics";
    }
    {
      key = "<leader>sh";
      mode = "n";
      action = "function() require('snacks').picker.help() end";
      lua = true;
      desc = "Help Pages";
    }
    {
      key = "<leader>sH";
      mode = "n";
      action = "function() require('snacks').picker.highlights() end";
      lua = true;
      desc = "Highlights";
    }
    {
      key = "<leader>si";
      mode = "n";
      action = "function() require('snacks').picker.icons() end";
      lua = true;
      desc = "Icons";
    }
    {
      key = "<leader>sj";
      mode = "n";
      action = "function() require('snacks').picker.jumps() end";
      lua = true;
      desc = "Jumps";
    }
    {
      key = "<leader>sk";
      mode = "n";
      action = "function() require('snacks').picker.keymaps() end";
      lua = true;
      desc = "Keymaps";
    }
    {
      key = "<leader>sl";
      mode = "n";
      action = "function() require('snacks').picker.loclist() end";
      lua = true;
      desc = "Location List";
    }
    {
      key = "<leader>sm";
      mode = "n";
      action = "function() require('snacks').picker.marks() end";
      lua = true;
      desc = "Marks";
    }
    {
      key = "<leader>sM";
      mode = "n";
      action = "function() require('snacks').picker.man() end";
      lua = true;
      desc = "Man Pages";
    }
    {
      key = "<leader>sp";
      mode = "n";
      action = "function() require('snacks').picker.lazy() end";
      lua = true;
      desc = "Search for Plugin Spec";
    }
    {
      key = "<leader>sq";
      mode = "n";
      action = "function() require('snacks').picker.qflist() end";
      lua = true;
      desc = "Quickfix List";
    }
    {
      key = "<leader>sR";
      mode = "n";
      action = "function() require('snacks').picker.resume() end";
      lua = true;
      desc = "Resume";
    }
    {
      key = "<leader>su";
      mode = "n";
      action = "function() require('snacks').picker.undo() end";
      lua = true;
      desc = "Undo History";
    }
    {
      key = "<leader>uC";
      mode = "n";
      action = "function() require('snacks').picker.colorschemes() end";
      lua = true;
      desc = "Colorschemes";
    }
    # LSP
    {
      key = "gd";
      mode = "n";
      action = "function() require('snacks').picker.lsp_definitions() end";
      lua = true;
      desc = "Goto Definition";
    }
    {
      key = "gD";
      mode = "n";
      action = "function() require('snacks').picker.lsp_declarations() end";
      lua = true;
      desc = "Goto Declaration";
    }
    {
      key = "gr";
      mode = "n";
      action = "function() require('snacks').picker.lsp_references() end";
      lua = true;
      desc = "References";
      nowait = true;
    }
    {
      key = "gI";
      mode = "n";
      action = "function() require('snacks').picker.lsp_implementations() end";
      lua = true;
      desc = "Goto Implementation";
    }
    {
      key = "gy";
      mode = "n";
      action = "function() require('snacks').picker.lsp_type_definitions() end";
      lua = true;
      desc = "Goto T[y]pe Definition";
    }
    {
      key = "gai";
      mode = "n";
      action = "function() require('snacks').picker.lsp_incoming_calls() end";
      lua = true;
      desc = "C[a]lls Incoming";
    }
    {
      key = "gao";
      mode = "n";
      action = "function() require('snacks').picker.lsp_outgoing_calls() end";
      lua = true;
      desc = "C[a]lls Outgoing";
    }
    {
      key = "<leader>ss";
      mode = "n";
      action = "function() require('snacks').picker.lsp_symbols() end";
      lua = true;
      desc = "LSP Symbols";
    }
    {
      key = "<leader>sS";
      mode = "n";
      action = "function() require('snacks').picker.lsp_workspace_symbols() end";
      lua = true;
      desc = "LSP Workspace Symbols";
    }
    # LSP Config
    {
      key = "<leader>cl";
      mode = "n";
      action = "function() require('snacks').picker.lsp_config() end";
      lua = true;
      desc = "Lsp Info";
    }
  ];

  # Register all picker keybinds with which-key
  binds.whichKey.register = {
    # Explorer
    "<leader>e" = "File Explorer";
    "<leader>E" = "File Explorer (cwd)";
    # Top Pickers
    "<leader><space>" = "Smart Find Files";
    "<leader>," = "Buffers";
    "<leader>/" = "Grep";
    "<leader>:" = "Command History";
    "<leader>n" = "Notification History";
    # find
    "<leader>fb" = "Buffers";
    "<leader>fc" = "Find Config File";
    "<leader>ff" = "Find Files";
    "<leader>fg" = "Find Git Files";
    "<leader>fp" = "Projects";
    "<leader>fr" = "Recent";
    # git
    "<leader>gb" = "Git Branches";
    "<leader>gl" = "Git Log";
    "<leader>gL" = "Git Log Line";
    "<leader>gs" = "Git Status";
    "<leader>gS" = "Git Stash";
    "<leader>gd" = "Git Diff (Hunks)";
    "<leader>gf" = "Git Log File";
    # gh
    "<leader>gi" = "GitHub Issues (open)";
    "<leader>gI" = "GitHub Issues (all)";
    "<leader>gp" = "GitHub Pull Requests (open)";
    "<leader>gP" = "GitHub Pull Requests (all)";
    # Grep
    "<leader>sb" = "Buffer Lines";
    "<leader>sB" = "Grep Open Buffers";
    "<leader>sg" = "Grep";
    "<leader>sw" = "Visual selection or word";
    # search
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
    "<leader>uC" = "Colorschemes";
    # LSP
    "gd" = "Goto Definition";
    "gD" = "Goto Declaration";
    "gr" = "References";
    "gI" = "Goto Implementation";
    "gy" = "Goto T[y]pe Definition";
    "gai" = "C[a]lls Incoming";
    "gao" = "C[a]lls Outgoing";
    "<leader>ss" = "LSP Symbols";
    "<leader>sS" = "LSP Workspace Symbols";
    # LSP Config
    "<leader>cl" = "Lsp Info";
  };
}
