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
      action = ''
        function()
          -- Ensure volt is loaded (required by nvchad.themes)
          if not package.loaded["volt"] then
            require("volt")
          end
          -- Load and open NvChad theme picker
          if package.loaded["nvchad-ui"] or package.loaded["nvchad"] then
            require("nvchad.themes").open()
          else
            vim.notify("NvChad themes not available - ensure nvchad-ui is loaded", vim.log.levels.WARN)
          end
        end
      '';
      lua = true;
      desc = "Colorschemes (NvChad)";
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

  # Note: which-key automatically discovers keymaps with desc attributes.
  # All keymaps above have desc, so they're auto-discovered.
  # We only need manual registrations for category prefixes (handled in which-key.nix).

  # NvChad-style theme for snacks picker (matches NvChad telescope theme)
  # NvChad-style theme for snacks picker (matches NvChad telescope theme)
  # This makes snacks picker look like NvChad's telescope picker
  luaConfigRC.snacks-picker-nvchad-theme = ''
    -- Debug command to inspect what highlight groups are actually being used
    vim.api.nvim_create_user_command("SnacksDebugIcons", function()
      local ok, snacks_util = pcall(require, "snacks.util")
      if ok then
        local icon, hl = snacks_util.icon("test.rs", "file")
        print("Rust file (.rs) icon: " .. (icon or "nil") .. ", highlight: " .. (hl or "nil"))
        local dir_icon, dir_hl = snacks_util.icon("src", "directory")
        print("Directory (src) icon: " .. (dir_icon or "nil") .. ", highlight: " .. (dir_hl or "nil"))
        local normal_dir_icon, normal_dir_hl = snacks_util.icon("folder", "directory")
        print("Directory (normal) icon: " .. (normal_dir_icon or "nil") .. ", highlight: " .. (normal_dir_hl or "nil"))
      end
      -- Check what DevIcon highlight groups exist
      local devicons = {}
      local all_hl = vim.api.nvim_get_hl(0, {})
      for name, _ in pairs(all_hl) do
        if name:match("^DevIcon") then
          table.insert(devicons, name)
        end
      end
      if #devicons > 0 then
        print("DevIcon groups found: " .. table.concat(devicons, ", "))
      else
        print("No DevIcon groups found")
      end
      -- Check MiniIcons groups
      local miniicons = {}
      for name, _ in pairs(all_hl) do
        if name:match("^MiniIcons") then
          table.insert(miniicons, name)
        end
      end
      if #miniicons > 0 then
        print("MiniIcons groups found: " .. table.concat(miniicons, ", "))
      end
    end, {})

    -- Set up NvChad-style highlights for snacks picker
    -- This makes it look like NvChad's telescope theme
    vim.defer_fn(function()
      -- Get colors from highlight groups (similar to NvChad telescope)
      local function get_hlgroup(name)
        local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
        return hl
      end

      local normal = get_hlgroup("Normal")
      local visual = get_hlgroup("Visual")
      local string_hl = get_hlgroup("String")
      local error_hl = get_hlgroup("Error")

      -- Get bg_dark (darker background for floats/pickers) - try to get from theme or use darker shade
      local bg = normal.bg or "#000000"
      local bg_dark = nil
      -- Try to get bg_dark from tokyonight theme if available
      local ok, theme = pcall(require, "themes.tokyonight_moon")
      if ok and theme and theme.base_30 then
        bg_dark = theme.base_30.darker_black or "#1e2030"
      else
        -- Fallback: use a slightly darker version of bg (for tokyonight moon: bg_dark is #1e2030 vs bg #222436)
        bg_dark = "#1e2030" -- tokyonight moon bg_dark
      end

      local bg_alt = visual.bg or "#1e1e2e"
      local green = string_hl.fg or "#98c379"
      local red = error_hl.fg or "#e06c75"
      local fg = normal.fg or "#abb2bf"

      -- Get orange color from theme (for borders)
      local orange = nil
      if ok and theme and theme.base_30 then
        orange = theme.base_30.orange or "#ff966c"
      else
        orange = "#ff966c" -- tokyonight moon orange
      end

      -- Set highlights for snacks picker to match tokyonight telescope theme
      -- Use bg_dark (darker blue) for picker background instead of normal bg
      -- Border should be orange (matching tokyonight's SnacksPickerInputBorder)
      vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = orange, bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPicker", { bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { fg = bg_dark, bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerPreviewTitle", { fg = bg_dark, bg = green })
      vim.api.nvim_set_hl(0, "SnacksPickerBoxBorder", { fg = bg_dark, bg = bg_dark })
      -- Input border should be orange (matching tokyonight)
      vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { fg = orange, bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerInputSearch", { fg = red, bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerListBorder", { fg = bg_dark, bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = bg_dark })
      vim.api.nvim_set_hl(0, "SnacksPickerListTitle", { fg = bg_dark, bg = bg_dark })


      -- Update highlights when colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("SnacksPickerNvChadTheme", { clear = true }),
        callback = function()
          local normal = get_hlgroup("Normal")
          local visual = get_hlgroup("Visual")
          local string_hl = get_hlgroup("String")
          local error_hl = get_hlgroup("Error")

          local bg = normal.bg or "#000000"
          local bg_dark = nil
          -- Try to get bg_dark from tokyonight theme if available
          local ok, theme = pcall(require, "themes.tokyonight_moon")
          if ok and theme and theme.base_30 then
            bg_dark = theme.base_30.darker_black or "#1e2030"
          else
            bg_dark = "#1e2030" -- tokyonight moon bg_dark fallback
          end

          local bg_alt = visual.bg or "#1e1e2e"
          local green = string_hl.fg or "#98c379"
          local red = error_hl.fg or "#e06c75"

          -- Get orange color from theme (for borders)
          local orange = nil
          if ok and theme and theme.base_30 then
            orange = theme.base_30.orange or "#ff966c"
          else
            orange = "#ff966c" -- tokyonight moon orange
          end

          -- Border should be orange (matching tokyonight's SnacksPickerInputBorder)
          vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = orange, bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPicker", { bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { fg = bg_dark, bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerPreviewTitle", { fg = bg_dark, bg = green })
          vim.api.nvim_set_hl(0, "SnacksPickerBoxBorder", { fg = bg_dark, bg = bg_dark })
          -- Input border should be orange (matching tokyonight)
          vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { fg = orange, bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerInputSearch", { fg = red, bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerListBorder", { fg = bg_dark, bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = bg_dark })
          vim.api.nvim_set_hl(0, "SnacksPickerListTitle", { fg = bg_dark, bg = bg_dark })

        end,
      })
    end, 0)
  '';
}
