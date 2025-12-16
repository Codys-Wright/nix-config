# Coding utilities (mini.ai, mini.pairs, treesitter textobjects, flash, etc.)
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Flash.nvim configuration (LazyVim-style)
  # Enhanced search functionality with labels for quick jumping
  # TEMPORARILY DISABLED to test if it's causing x key timeout
  utility = {
    motion = {
      flash-nvim = {
        enable = true;
        # LazyVim-style mappings (using gs prefix to avoid conflicts)
        mappings = {
          jump = "gs"; # Flash jump (changed from s to gs)
          treesitter = "gS"; # Flash Treesitter (changed from S to gS)
          remote = "r"; # Remote Flash
          treesitter_search = "R"; # Treesitter Search
          toggle = "<c-s>"; # Toggle Flash Search
        };
        setupOpts = {
          # Default config is fine, but we can customize if needed
        };
      };
    };

    # Yanky.nvim configuration (LazyVim-style)
    # Better yank/paste with history
    yanky-nvim = {
      enable = true;
      setupOpts = {
        # Use sqlite storage for better reliability (as requested)
        ring = {
          storage = "sqlite";
        };
        # Sync with system clipboard (unless in SSH)
        system_clipboard = {
          sync_with_ring = lib.generators.mkLuaInline "not vim.env.SSH_CONNECTION";
        };
        # Highlight yanked text
        highlight = {
          timer = 150;
        };
      };
    };
  };

  # Mini.ai configuration (LazyVim-style)
  # Extends the a & i text objects with treesitter support
  mini = {
    ai = {
      enable = true;
      setupOpts = {
        n_lines = 500;
        custom_textobjects = lib.generators.mkLuaInline ''
          (function()
            local ai = require("mini.ai")
            -- LazyVim-style ai_buffer function (from LazyVim.util.mini)
            local function ai_buffer(ai_type)
              local start_line, end_line = 1, vim.fn.line("$")
              if ai_type == "i" then
                -- Skip first and last blank lines for `i` textobject
                local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
                -- Do nothing for buffer with all blanks
                if first_nonblank == 0 or last_nonblank == 0 then
                  return { from = { line = start_line, col = 1 } }
                end
                start_line, end_line = first_nonblank, last_nonblank
              end
              local to_col = math.max(vim.fn.getline(end_line):len(), 1)
              return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
            end

            return {
              o = ai.gen_spec.treesitter({ -- code block
                a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                i = { "@block.inner", "@conditional.inner", "@loop.inner" },
              }),
              f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
              c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
              t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
              d = { "%f[%d]%d+" }, -- digits
              e = { -- Word with case
                { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
                "^().*()$",
              },
              g = ai_buffer, -- buffer (entire file)
              u = ai.gen_spec.function_call(), -- u for "Usage"
              U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
            }
          end)()
        '';
      };
    };

    # Mini.pairs configuration (LazyVim-style)
    pairs = {
      enable = true;
      setupOpts = {
        modes = {
          insert = true;
          command = true;
          terminal = false;
        };
        # skip autopair when next character is one of these
        skip_next = lib.generators.mkLuaInline "[=[[%w%%%'%[%\"%.%`%$]]=]";
        # skip autopair when the cursor is inside these treesitter nodes
        skip_ts = ["string"];
        # skip autopair when next character is closing pair
        # and there are more closing pairs than opening pairs
        skip_unbalanced = true;
        # better deal with markdown code blocks
        markdown = true;
      };
    };

    # Mini.surround configuration (LazyVim-style)
    # Fast and feature-rich surround actions
    surround = {
      enable = true;
      setupOpts = {
        # LazyVim-style mappings (gs prefix)
        #   mappings = {
        #     add = "gsa"; # Add surrounding in Normal and Visual modes
        #     delete = "gsd"; # Delete surrounding
        #     find = "gsf"; # Find surrounding (to the right)
        #     find_left = "gsF"; # Find surrounding (to the left)
        #     highlight = "gsh"; # Highlight surrounding
        #     replace = "gsr"; # Replace surrounding
        #     update_n_lines = "gsn"; # Update `n_lines`
        #   };
      };
    };
  };

  # Add yanky keymaps (LazyVim-style)
  # Note: yanky uses <Plug> mappings, so we need to use luaConfigRC to set them up
  luaConfigRC.yanky-keymaps = ''
    -- Yanky keymaps (LazyVim-style)
    vim.defer_fn(function()
      if package.loaded["yanky"] then
        -- Open yank history with snacks picker (LazyVim-style)
        vim.keymap.set({ "n", "x" }, "<leader>p", function()
          if Snacks and Snacks.picker then
            Snacks.picker.yanky()
          else
            vim.cmd([[YankyRingHistory]])
          end
        end, { desc = "Open Yank History" })

        -- Yanky plug mappings (these are set up by yanky automatically)
        -- y, p, P, gp, gP, [y, ]y, [p, ]p, [P, ]P, >p, <p, >P, <P, =p, =P
      end
    end, 0)
  '';

  # Treesitter textobjects configuration (LazyVim-style)
  treesitter = {
    textobjects = {
      enable = true;
      setupOpts = {
        move = {
          enable = true;
          set_jumps = true; # whether to set jumps in the jumplist
          # LazyVim-style keymaps for navigating textobjects
          keys = {
            goto_next_start = {
              "]f" = "@function.outer";
              "]c" = "@class.outer";
              "]a" = "@parameter.inner";
            };
            goto_next_end = {
              "]F" = "@function.outer";
              "]C" = "@class.outer";
              "]A" = "@parameter.inner";
            };
            goto_previous_start = {
              "[f" = "@function.outer";
              "[c" = "@class.outer";
              "[a" = "@parameter.inner";
            };
            goto_previous_end = {
              "[F" = "@function.outer";
              "[C" = "@class.outer";
              "[A" = "@parameter.inner";
            };
          };
        };
      };
    };
  };

  # Register mini.ai text objects with which-key (LazyVim-style)
  # This needs to run after both mini.ai and which-key are loaded
  luaConfigRC.mini-ai-whichkey = ''
    -- Register mini.ai text objects with which-key (LazyVim-style)
    -- This runs after mini.ai and which-key are loaded
    vim.defer_fn(function()
      if package.loaded["mini.ai"] and package.loaded["which-key"] then
        local ai = require("mini.ai")
        local opts = require("mini.ai").config or {}
        local objects = {
          { " ", desc = "whitespace" },
          { '"', desc = '" string' },
          { "'", desc = "' string" },
          { "(", desc = "() block" },
          { ")", desc = "() block with ws" },
          { "<", desc = "<> block" },
          { ">", desc = "<> block with ws" },
          { "?", desc = "user prompt" },
          { "U", desc = "use/call without dot" },
          { "[", desc = "[] block" },
          { "]", desc = "[] block with ws" },
          { "_", desc = "underscore" },
          { "`", desc = "` string" },
          { "a", desc = "argument" },
          { "b", desc = ")]} block" },
          { "c", desc = "class" },
          { "d", desc = "digit(s)" },
          { "e", desc = "CamelCase / snake_case" },
          { "f", desc = "function" },
          { "g", desc = "entire file" },
          { "i", desc = "indent" },
          { "o", desc = "block, conditional, loop" },
          { "q", desc = "quote `\"'" },
          { "t", desc = "tag" },
          { "u", desc = "use/call" },
          { "{", desc = "{} block" },
          { "}", desc = "{} with ws" },
        }

        local ret = { mode = { "o", "x" } }
        local mappings = {
          around = "a",
          inside = "i",
          around_next = "an",
          inside_next = "in",
          around_last = "al",
          inside_last = "il",
        }

        for name, prefix in pairs(mappings) do
          name = name:gsub("^around_", ""):gsub("^inside_", "")
          ret[#ret + 1] = { prefix, group = name }
          for _, obj in ipairs(objects) do
            local desc = obj.desc
            if prefix:sub(1, 1) == "i" then
              desc = desc:gsub(" with ws", "")
            end
            ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
          end
        end
        require("which-key").add(ret, { notify = false })
      end
    end, 0)
  '';

  # Mini.pairs toggle (LazyVim-style)
  # Add toggle for mini.pairs via Snacks
  luaConfigRC.mini-pairs-toggle = ''
    -- Mini.pairs toggle (LazyVim-style)
    vim.defer_fn(function()
      if Snacks and Snacks.toggle and package.loaded["mini.pairs"] then
        Snacks.toggle({
          name = "Mini Pairs",
          get = function()
            return not vim.g.minipairs_disable
          end,
          set = function(state)
            vim.g.minipairs_disable = not state
          end,
        }):map("<leader>up")
      end
    end, 0)
  '';

  # Comment-nvim configuration (LazyVim uses ts-comments, but comment-nvim is available in nvf)
  comments = {
    comment-nvim = {
      enable = true;
      # Use LazyVim-style mappings (gc for line, gb for block)
      mappings = {
        toggleOpLeaderLine = "gc";
        toggleOpLeaderBlock = "gb";
        toggleCurrentLine = "gcc";
        toggleCurrentBlock = "gbc";
        toggleSelectedLine = "gc";
        toggleSelectedBlock = "gb";
      };
      setupOpts = {
        # Enable basic mappings (gc, gb, etc.)
        mappings.basic = true;
        # Enable extra mappings
        mappings.extra = true;
      };
    };
  };

  # Todo-comments configuration (LazyVim-style with snacks picker integration)
  notes = {
    todo-comments = {
      enable = true;
      # LazyVim-style mappings
      mappings = {
        quickFix = "<leader>tdq";
        telescope = "<leader>tds";
        trouble = "<leader>tdt";
      };
      setupOpts = {
        # Default config is fine, but we can customize if needed
      };
    };
  };

  # Add snacks picker integration for todo-comments (LazyVim-style)
  # This adds <leader>st and <leader>sT keymaps for snacks picker
  # Also add flash.nvim treesitter incremental selection
  keymaps = [
    # Flash treesitter incremental selection (LazyVim-style)
    {
      key = "<c-space>";
      mode = ["n" "o" "x"];
      action = ''
        function()
          require("flash").treesitter({
            actions = {
              ["<c-space>"] = "next",
              ["<BS>"] = "prev"
            }
          })
        end
      '';
      lua = true;
      desc = "Treesitter Incremental Selection";
    }
    # Grug-far keymap (LazyVim-style)
    {
      key = "<leader>sr";
      mode = ["n" "x"];
      action = ''
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end
      '';
      lua = true;
      desc = "Search and Replace";
    }
    {
      key = "<leader>st";
      mode = "n";
      action = "function() if Snacks and Snacks.picker then Snacks.picker.todo_comments() end end";
      lua = true;
      desc = "Todo (Snacks Picker)";
    }
    {
      key = "<leader>sT";
      mode = "n";
      action = "function() if Snacks and Snacks.picker then Snacks.picker.todo_comments({ keywords = { 'TODO', 'FIX', 'FIXME' } }) end end";
      lua = true;
      desc = "Todo/Fix/Fixme (Snacks Picker)";
    }
    # Todo navigation (LazyVim-style)
    {
      key = "]t";
      mode = "n";
      action = "function() require('todo-comments').jump_next() end";
      lua = true;
      desc = "Next Todo Comment";
    }
    {
      key = "[t";
      mode = "n";
      action = "function() require('todo-comments').jump_prev() end";
      lua = true;
      desc = "Previous Todo Comment";
    }
    # Grug-far keymap (LazyVim-style) - duplicate removed, already defined above
  ];

  # Note: which-key automatically discovers keymaps with desc attributes.
  # Plugin-configured keymaps (treesitter textobjects, mini.surround, yanky, flash)
  # will be discovered automatically if they have desc attributes set by the plugins.
  # We only need manual registrations for category prefixes (handled in which-key.nix).

  # Grug-far.nvim - Search/replace in multiple files (LazyVim-style)
  # The package is passed from nvf.nix (from nixpkgs)
  extraPlugins = {
    grug-far = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      setup = ''
        require('grug-far').setup({
          headerMaxWidth = 80,
        })
      '';
    };

    # vim-repeat - Enhanced repeat functionality
    # The package is passed from nvf.nix (from nixpkgs)
    vim-repeat = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      # vim-repeat doesn't need setup, just needs to be loaded
    };
  };
}
