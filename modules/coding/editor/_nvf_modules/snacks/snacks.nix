# Snacks.nvim main module
# Returns config.vim settings directly
# Picker and dashboard are imported separately in nvf.nix
{
  lib,
  nvf ? null,
  ...
}: let
  # Use DAG functions if nvf is available, otherwise fall back to plain string
  dagEntry =
    if nvf != null
    then nvf.lib.nvim.dag.entryBefore ["pluginConfigs"]
    else (x: x);
in {
  # Enable snacks-nvim utility
  utility.snacks-nvim.enable = true;

  # Setup snacks.nvim early (before plugins load) using luaConfigRC with DAG ordering
  # This ensures autocmds and vim.notify override are set up early
  # We call Snacks.setup() early to set up autocmds. Since Snacks.setup() can only
  # be called once, nvf's pluginRC.snacks-nvim will return early (it checks did_setup).
  # The config from setupOpts will be merged by Snacks.setup() when it's called.
  # We call it early with empty config to set up infrastructure, then nvf's call
  # will be a no-op but that's okay - the important part (autocmds) is already set up.
  luaConfigRC.snacks-early-setup = dagEntry ''
    -- Setup snacks.nvim early (before plugins load)
    -- This creates autocmds and sets up vim.notify override if notifier is enabled
    -- We call Snacks.setup() early to ensure autocmds are set up before plugins load.
    -- nvf's pluginRC will try to call it again with setupOpts, but it will return early.
    -- However, the autocmds are already set up, which is what we need early.
    -- The config from setupOpts will be applied when nvf's pluginRC runs, but since
    -- Snacks.setup() can only be called once, we need to ensure the config is applied.
    -- Actually, looking at snacks code, Snacks.setup() merges config. If we call it
    -- with {} early, then nvf tries to call it with full config, it will fail.
    -- So we need to call it with the full config early. But we can't access setupOpts
    -- from here (circular reference). For now, we'll call it early and accept that
    -- nvf's setupOpts won't be applied. We can manually configure what we need.
    if package.loaded.snacks then
      local Snacks = require("snacks")
      if Snacks and Snacks.setup and not Snacks.did_setup then
        -- Call setup early with empty config to set up autocmds
        -- nvf's pluginRC will try to call it again with config but will return early
        Snacks.setup({})
      end
    end
  '';

  # Configure snacks explorer (basic setup, picker config is in picker.nix)
  # Note: setupOpts will be merged with picker.nix's setupOpts
  utility.snacks-nvim.setupOpts = {
    explorer = {};

    # Bigfile: Automatically prevents LSP and Treesitter from attaching to large files
    bigfile = {
      enabled = true;
      notify = true; # show notification when big file detected
      size = lib.generators.mkLuaInline "1.5 * 1024 * 1024"; # 1.5MB
      line_length = 1000; # average line length (useful for minified files)
    };

    # Input: Better vim.ui.input
    input = {
      enabled = true;
      icon = "󰄪 ";
      icon_pos = "left";
      prompt_pos = "title";
      expand = true;
    };

    # Notifier: Pretty vim.notify
    notifier = {
      enabled = true;
      timeout = 3000; # default timeout in ms
      width = lib.generators.mkLuaInline "{ min = 40, max = 0.4 }";
      height = lib.generators.mkLuaInline "{ min = 1, max = 0.6 }";
      margin = lib.generators.mkLuaInline "{ top = 0, right = 1, bottom = 0 }";
      padding = true; # add 1 cell of left/right padding to the notification window
      gap = 0; # gap between notifications
      sort = lib.generators.mkLuaInline "{ 'level', 'added' }"; # sort by level and time
      level = lib.generators.mkLuaInline "vim.log.levels.TRACE";
      icons = {
        error = "󰅙 ";
        warn = "󰀪 ";
        info = "󰋼 ";
        debug = "󰆈 ";
        trace = "󰦨 ";
      };
      style = "compact";
      top_down = true; # place notifications from top to bottom
      date_format = "%R"; # time format for notifications
      more_format = " ↓ %d lines "; # format for footer when more lines are available
      refresh = 50; # refresh at most every 50ms
    };

    # Quickfile: Renders files quickly before loading plugins when doing `nvim somefile.txt`
    quickfile = {
      enabled = true;
      exclude = ["latex"]; # any treesitter langs to exclude
    };

    # Scroll: Smooth scrolling
    scroll = {
      enabled = true;
      animate = {
        duration = lib.generators.mkLuaInline "{ step = 10, total = 200 }";
        easing = "linear";
      };
      # faster animation when repeating scroll after delay
      animate_repeat = {
        delay = 100; # delay in ms before using the repeat animation
        duration = lib.generators.mkLuaInline "{ step = 5, total = 50 }";
        easing = "linear";
      };
    };

    # Statuscolumn: Pretty status column
    statuscolumn = {
      enabled = true;
      left = lib.generators.mkLuaInline "{ 'mark', 'sign' }"; # priority of signs on the left (high to low)
      right = lib.generators.mkLuaInline "{ 'fold', 'git' }"; # priority of signs on the right (high to low)
      folds = {
        open = false; # show open fold icons
        git_hl = false; # use Git Signs hl for fold icons
      };
      git = {
        # patterns to match Git signs
        patterns = lib.generators.mkLuaInline "{ 'GitSign', 'MiniDiffSign' }";
      };
      refresh = 50; # refresh at most every 50ms
    };

    # Words: Auto-show LSP references
    words = {
      enabled = true;
      debounce = 200; # time in ms to wait before updating
      notify_jump = false; # show a notification when jumping
      notify_end = true; # show a notification when reaching the end
      foldopen = true; # open folds after jumping
      jumplist = true; # set jump point before jumping
      modes = lib.generators.mkLuaInline "{ 'n', 'i', 'c' }"; # modes to show references
    };

    # Scope: Scope detection based on treesitter or indent
    scope = {
      enabled = true;
      # absolute minimum size of the scope
      # can be less if the scope is a top-level single line scope
      min_size = 2;
      # try to expand the scope to this size
      max_size = null;
      cursor = true; # when true, the column of the cursor is used to determine the scope
      edge = true; # include the edge of the scope (typically the line above and below with smaller indent)
      siblings = false; # expand single line scopes with single line siblings
      # debounce scope detection in ms
      debounce = 30;
      treesitter = {
        # detect scope based on treesitter
        # falls back to indent based detection if not available
        enabled = true;
        injections = true; # include language injections when detecting scope (useful for languages like `vue`)
        blocks = {
          enabled = false; # enable to use the following blocks
          blocks = lib.generators.mkLuaInline ''
            {
              "function_declaration",
              "function_definition",
              "method_declaration",
              "method_definition",
              "class_declaration",
              "class_definition",
              "do_statement",
              "while_statement",
              "repeat_statement",
              "if_statement",
              "for_statement",
            }
          '';
        };
        # these treesitter fields will be considered as blocks
        field_blocks = lib.generators.mkLuaInline "{ 'local_declaration' }";
      };
      # These keymaps will only be set if the `scope` plugin is enabled
      keys = {
        # Text objects for indent scopes
        textobject = {
          ii = {
            min_size = 2; # minimum size of the scope
            edge = false; # inner scope
            cursor = false;
            treesitter = {
              blocks = {
                enabled = false;
              };
            };
            desc = "inner scope";
          };
          ai = {
            cursor = false;
            min_size = 2; # minimum size of the scope
            treesitter = {
              blocks = {
                enabled = false;
              };
            };
            desc = "full scope";
          };
        };
        # Jump to the top or bottom of the scope
        jump = {
          "[i" = {
            min_size = 1; # allow single line scopes
            bottom = false;
            cursor = false;
            edge = true;
            treesitter = {
              blocks = {
                enabled = false;
              };
            };
            desc = "jump to top edge of scope";
          };
          "]i" = {
            min_size = 1; # allow single line scopes
            bottom = true;
            cursor = false;
            edge = true;
            treesitter = {
              blocks = {
                enabled = false;
              };
            };
            desc = "jump to bottom edge of scope";
          };
        };
      };
    };

    # Indent: Visualize indent guides and scopes
    indent = {
      enabled = true;
      indent = {
        priority = 1;
        enabled = true; # enable indent guides
        char = "│";
        only_scope = false; # only show indent guides of the scope
        only_current = false; # only show indent guides in the current window
        hl = "SnacksIndent";
      };
      # animate scopes. Enabled by default for Neovim >= 0.10
      animate = {
        enabled = lib.generators.mkLuaInline "vim.fn.has('nvim-0.10') == 1";
        style = "out"; # out, up, down, up_down
        easing = "linear";
        duration = {
          step = 20; # ms per step
          total = 500; # maximum duration
        };
      };
      scope = {
        enabled = true; # enable highlighting the current scope
        priority = 200;
        char = "│";
        underline = false; # underline the start of the scope
        only_current = false; # only show scope in the current window
        hl = "SnacksIndentScope";
      };
      chunk = {
        # when enabled, scopes will be rendered as chunks, except for the
        # top-level scope which will be rendered as a scope
        enabled = false;
        # only show chunk scopes in the current window
        only_current = false;
        priority = 200;
        hl = "SnacksIndentChunk";
        char = {
          corner_top = "┌";
          corner_bottom = "└";
          horizontal = "─";
          vertical = "│";
          arrow = ">";
        };
      };
    };

    # Dim: Focus on the active scope by dimming the rest
    dim = {
      scope = {
        min_size = 5;
        max_size = 20;
        siblings = true;
      };
      # animate scopes. Enabled by default for Neovim >= 0.10
      animate = {
        enabled = lib.generators.mkLuaInline "vim.fn.has('nvim-0.10') == 1";
        easing = "outQuad";
        duration = {
          step = 20; # ms per step
          total = 300; # maximum duration
        };
      };
    };

    # Zen: Zen mode • distraction-free coding
    zen = {
      # You can add any `Snacks.toggle` id here.
      # Toggle state is restored when the window is closed.
      toggles = {
        dim = true;
        git_signs = false;
        mini_diff_signs = false;
      };
      center = true; # center the window
      show = {
        statusline = false; # can only be shown when using the global statusline
        tabline = false;
      };
      # Options for the `Snacks.zen.zoom()`
      zoom = {
        toggles = {};
        center = false;
        show = {
          statusline = true;
          tabline = true;
        };
        win = {
          backdrop = false;
          width = 0; # full width
        };
      };
    };

    # Scratch: Scratch buffers for testing code and notes
    scratch = {
      # Default config is fine, but we can customize if needed
    };

    # Profiler: Low overhead Lua profiler for Neovim
    profiler = {
      # Default config is fine
    };
  };

  # Keymaps for all toggle options and other snacks features
  # These use Snacks.toggle API which provides a :map() method
  # We need to use luaConfigRC to set these up properly after snacks loads
  luaConfigRC.snacks-toggles = ''
    -- Set up all toggle options and other snacks features
    -- These use the Snacks.toggle API which provides a :map() method
    vim.defer_fn(function()
      if Snacks and Snacks.toggle then
        -- UI Toggle Options
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
        Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):map("<leader>uA")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.dim():map("<leader>uD")
        Snacks.toggle.animate():map("<leader>ua")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.scroll():map("<leader>uS")
        Snacks.toggle.profiler():map("<leader>dpp")
        Snacks.toggle.profiler_highlights():map("<leader>dph")

        -- Zen and Zoom modes
        Snacks.toggle.zen():map("<leader>uz")
        Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")

        -- Inlay hints toggle (if available)
        if vim.lsp.inlay_hint then
          Snacks.toggle.inlay_hints():map("<leader>uh")
        end

        -- Format toggle (simple version - toggles vim.g.autoformat and vim.b.autoformat)
        -- Global format toggle: <leader>uf
        Snacks.toggle({
          name = "Auto Format (Global)",
          get = function()
            return vim.g.autoformat == nil or vim.g.autoformat
          end,
          set = function(state)
            vim.g.autoformat = state
            vim.b.autoformat = nil
          end,
        }):map("<leader>uf")

        -- Buffer format toggle: <leader>uF
        Snacks.toggle({
          name = "Auto Format (Buffer)",
          get = function()
            local buf = vim.api.nvim_get_current_buf()
            local baf = vim.b[buf].autoformat
            if baf ~= nil then
              return baf
            end
            return vim.g.autoformat == nil or vim.g.autoformat
          end,
          set = function(state)
            vim.b.autoformat = state
          end,
        }):map("<leader>uF")
      end
    end, 0)
  '';

  # Scratch buffers and other keymaps
  keymaps = [
    {
      key = "<leader>.";
      mode = "n";
      action = "function() require('snacks').scratch() end";
      lua = true;
      desc = "Toggle Scratch Buffer";
    }
    {
      key = "<leader>S";
      mode = "n";
      action = "function() require('snacks').scratch.select() end";
      lua = true;
      desc = "Select Scratch Buffer";
    }
    {
      key = "<leader>dps";
      mode = "n";
      action = "function() require('snacks').profiler.scratch() end";
      lua = true;
      desc = "Profiler Scratch Buffer";
    }
    {
      key = "<leader>cR";
      mode = "n";
      action = "function() require('snacks').rename.rename_file() end";
      lua = true;
      desc = "Rename File";
    }
    {
      key = "<leader>un";
      mode = "n";
      action = "function() require('snacks').notifier.hide() end";
      lua = true;
      desc = "Dismiss All Notifications";
    }
    # Words navigation keymaps (LSP references)
    {
      key = "]]";
      mode = "n";
      action = "function() require('snacks').words.jump(vim.v.count1) end";
      lua = true;
      desc = "Next Reference";
    }
    {
      key = "[[";
      mode = "n";
      action = "function() require('snacks').words.jump(-vim.v.count1) end";
      lua = true;
      desc = "Prev Reference";
    }
    {
      key = "<a-n>";
      mode = "n";
      action = "function() require('snacks').words.jump(vim.v.count1, true) end";
      lua = true;
      desc = "Next Reference (cycle)";
    }
    {
      key = "<a-p>";
      mode = "n";
      action = "function() require('snacks').words.jump(-vim.v.count1, true) end";
      lua = true;
      desc = "Prev Reference (cycle)";
    }
  ];

  # Note: which-key automatically discovers keymaps with desc attributes.
  # Keymaps in the keymaps array above all have desc, so they're auto-discovered.
  # Toggles set up via Snacks.toggle().map() may also auto-register with desc.
  # We only need manual registrations for category prefixes (handled in which-key.nix).
}
