# Git integration (gitsigns, git navigation, etc.)
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Git integration with gitsigns
  git = {
    enable = true;
    gitsigns = {
      enable = true;
      # LazyVim-style gitsigns configuration
      setupOpts = {
        signs = {
          add = { text = "│"; };
          change = { text = "│"; };
          delete = { text = ""; };
          topdelete = { text = ""; };
          changedelete = { text = "▎"; };
          untracked = { text = "▎"; };
        };
        signs_staged = {
          add = { text = "│"; };
          change = { text = "│"; };
          delete = { text = ""; };
          topdelete = { text = ""; };
          changedelete = { text = "│"; };
        };
        on_attach = lib.generators.mkLuaInline ''
          function(buffer)
            local gs = package.loaded.gitsigns

            local function map(mode, l, r, desc)
              vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
            end

            -- Navigation (LazyVim-style)
            map("n", "]h", function()
              if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
              else
                gs.nav_hunk("next")
              end
            end, "Next Hunk")
            map("n", "[h", function()
              if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
              else
                gs.nav_hunk("prev")
              end
            end, "Prev Hunk")
            map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
            map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")

            -- Actions (LazyVim-style)
            map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
            map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
            map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
            map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
            map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
            map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
            map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
            map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
            map("n", "<leader>ghd", gs.diffthis, "Diff This")
            map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")

            -- Text object (LazyVim-style)
            map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
          end
        '';
      };
    };
  };

  # LazyGit integration with toggleterm
  terminal = {
    toggleterm = {
      lazygit = {
        enable = true;
        direction = "float";
        mappings = {
          open = "<leader>gg";
        };
      };
    };
  };



  # Gitsigns toggle integration with Snacks
  # This sets up a toggle for gitsigns that works with Snacks.toggle
  luaConfigRC.gitsigns-snacks-toggle = ''
    -- Setup Snacks toggle for Git Signs (LazyVim-style)
    vim.defer_fn(function()
      if Snacks and Snacks.toggle then
        Snacks.toggle({
          name = "Git Signs",
          get = function()
            return require("gitsigns.config").config.signcolumn
          end,
          set = function(state)
            require("gitsigns").toggle_signs(state)
          end,
        }):map("<leader>uG")
      end
    end, 0)
  '';

  # LazyGit additional keymaps (LazyVim-style)
  keymaps = [
    # LazyGit root dir (uses LazyVim root detection)
    {
      key = "<leader>gG";
      mode = "n";
      action = ":lua if Snacks and Snacks.lazygit then Snacks.lazygit({ cwd = LazyVim.root.git() }) else vim.cmd('TermExec cmd=\\'lazygit\\' direction=float') end<CR>";
      desc = "Lazygit (Root Dir)";
    }
    # Git browse (open current file/line in browser)
    {
      key = "<leader>gb";
      mode = "n";
      action = ":lua if Snacks and Snacks.gitbrowse then Snacks.gitbrowse() end<CR>";
      desc = "Git Browse";
    }
    # Git browse (open and browse)
    {
      key = "<leader>gB";
      mode = "n";
      action = ":lua if Snacks and Snacks.gitbrowse then Snacks.gitbrowse({ open = true }) end<CR>";
      desc = "Git Browse (Open)";
    }
    # LazyGit current file history
    {
      key = "<leader>gf";
      mode = "n";
      action = "function() local git_path = vim.api.nvim_buf_get_name(0); if Snacks and Snacks.lazygit then Snacks.lazygit({args = { '-f', vim.api.nvim_buf_get_name(0) }}) else vim.cmd('TermExec cmd=lazygit -f ' .. git_path .. ' direction=float') end end";
      lua = true;
      desc = "Lazygit Current File History";
    }
    # LazyGit log
    {
      key = "<leader>gl";
      mode = "n";
      action = "function() if Snacks and Snacks.lazygit then Snacks.lazygit({ args = { 'log' }, cwd = LazyVim.root.git() }) else vim.cmd('TermExec cmd=lazygit log direction=float') end end";
      lua = true;
      desc = "Lazygit Log";
    }
    # LazyGit log (current directory)
    {
      key = "<leader>gL";
      mode = "n";
      action = "function() if Snacks and Snacks.lazygit then Snacks.lazygit({ args = { 'log' } }) else vim.cmd('TermExec cmd=lazygit log direction=float') end end";
      lua = true;
      desc = "Lazygit Log (cwd)";
    }
  ];
}
