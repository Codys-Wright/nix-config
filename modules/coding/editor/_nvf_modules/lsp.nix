# LSP configuration and features
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Enable mini.snippets as the snippet provider
  # Configure it to load snippets from friendly-snippets (like LazyVim does)
  mini = {
    snippets = {
      enable = true;
      # Configure snippets loader to use gen_loader.from_lang()
      # This automatically loads snippets from friendly-snippets and other runtimepath sources
      # LazyVim uses: snippets = { mini_snippets.gen_loader.from_lang() }
      # We need to use mkLuaInline because gen_loader.from_lang() is a function that must be called
      setupOpts = {
        snippets = lib.generators.mkLuaInline ''
          (function()
            local mini_snippets = require("mini.snippets")
            return { mini_snippets.gen_loader.from_lang() }
          end)()
        '';
      };
    };
  };

  # LSP configuration
  lsp = {
    enable = true;
    formatOnSave = true;
    lightbulb.enable = true;
    trouble = {
      enable = true;
      # LazyVim-style trouble configuration
      setupOpts = {
        modes = {
          lsp = {
            win = {
              position = "right";
            };
          };
        };
      };
      # LazyVim-style trouble keymaps
      mappings = {
        documentDiagnostics = "<leader>xx"; # Diagnostics toggle
        workspaceDiagnostics = "<leader>xX"; # Buffer Diagnostics toggle
        # symbols removed - using <leader>cs for aerial instead
        lspReferences = "<leader>cS"; # LSP references/definitions toggle
        locList = "<leader>xL"; # Location List toggle
        quickfix = "<leader>xQ"; # Quickfix List toggle
      };
    };
    # lspSignature is disabled when using blink.cmp
    # Use blink.cmp's builtin signature feature instead
    lspSignature.enable = false;
  };

  # Enable trouble_lualine (shows trouble symbols in lualine)
  globals = {
    trouble_lualine = true;
  };

  # Inline diagnostics configuration (LazyVim-style)
  # This configures vim.diagnostic.config() to show inline virtual text
  diagnostics = {
    enable = true;
    config = {
      underline = true;
      update_in_insert = false;
      virtual_text = {
        spacing = 4;
        source = lib.generators.mkLuaInline "\"if_many\"";
        prefix = lib.generators.mkLuaInline "\"●\"";
        # Alternative: use icons based on severity
        # prefix = lib.generators.mkLuaInline ''
        #   function(diagnostic)
        #     local icons = {
        #       Error = "󰅚 ",
        #       Warn = "󰀪 ",
        #       Hint = "󰆈 ",
        #       Info = "󰋼 ",
        #     }
        #     for d, icon in pairs(icons) do
        #       if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
        #         return icon
        #       end
        #     end
        #     return "●"
        #   end
        # '';
      };
      severity_sort = true;
      signs = {
        text = lib.generators.mkLuaInline ''
          {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.HINT] = "󰆈 ",
            [vim.diagnostic.severity.INFO] = "󰋼 ",
          }
        '';
      };
    };
  };

  # Blink.cmp configuration (NvChad's new completion engine)
  # Uses NvChad's blink configuration and base46 highlights
  autocomplete = {
    blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      # Use LazyVim-style blink configuration
      # Based on LazyVim's blink.lua configuration
      setupOpts = {
        snippets = lib.mkForce {
          preset = "mini_snippets"; # Use mini.snippets instead of luasnip
        };
        cmdline = {
          enabled = true; # Enable cmdline completion
          # Use default sources for cmdline (null means use default source list)
          sources = null;
          keymap = {
            preset = "cmdline";
            # Disable Left/Right arrows in cmdline (don't include them in keymap)
            # "<Right>" and "<Left>" are not set, so they won't be mapped
          };
          completion = {
            list = {
              selection = {
                preselect = false;
              };
            };
            menu = {
              auto_show = lib.generators.mkLuaInline "function(ctx) return vim.fn.getcmdtype() == ':' end";
            };
            ghost_text = {
              enabled = true;
            };
          };
        };
        appearance = {
          nerd_font_variant = "mono"; # LazyVim uses "mono" for better alignment
        };
        fuzzy = {
          implementation = "prefer_rust";
          # Prioritize snippets over other sources
          # Custom sort function that gives snippets highest priority
          sorts = lib.generators.mkLuaInline ''
            {
              function(a, b)
                -- Define source priorities (higher number = higher priority)
                local source_priority = {
                  snippets = 4,
                  lsp = 3,
                  path = 2,
                  buffer = 1,
                }
                local a_priority = source_priority[a.source_id] or 0
                local b_priority = source_priority[b.source_id] or 0
                -- If priorities differ, sort by priority
                if a_priority ~= b_priority then
                  return a_priority > b_priority
                end
                -- Otherwise use default sorting (score, then sort_text)
                if a.score ~= b.score then
                  return a.score > b.score
                end
                return (a.sort_text or "") < (b.sort_text or "")
              end,
              "score",
              "sort_text",
            }
          '';
        };
        sources = {
          # Put snippets first in the list to prioritize them
          # Combined with custom fuzzy.sorts, this ensures snippets appear at the top
          default = ["snippets" "lsp" "buffer" "path"];
          providers = {
          };
        };
        keymap = {
          preset = "enter"; # LazyVim uses "enter" preset (Enter to accept)
          "<C-y>" = ["select_and_accept"]; # LazyVim adds C-y for select_and_accept
          # Force Tab to ONLY do snippet_forward (override nvf's default which has select_next first)
          # nvf's config.nix sets mappings.next (Tab) to ["select_next" "snippet_forward" ...]
          # We need to completely override this to remove select_next
          "<Tab>" = lib.mkForce ["snippet_forward"];
          # Force Shift+Tab to ONLY do snippet_backward (override nvf's default)
          "<S-Tab>" = lib.mkForce ["snippet_backward"];
        };
        signature = {
          enabled = true;
        };
        completion = {
          accept = {
            # experimental auto-brackets support (LazyVim enables this)
            auto_brackets = {
              enabled = true;
            };
          };
          menu = {
            auto_show = true; # Show menu automatically (set to false to only show on manual <C-space>)
            draw = {
              treesitter = ["lsp"]; # LazyVim enables treesitter in menu draw
            };
          };
          ghost_text = {
            enabled = true; # Enable ghost text preview of selected item
            show_with_menu = true; # Only show ghost text when menu is closed
          };
          documentation = {
            auto_show = true; # Show documentation whenever an item is selected
            auto_show_delay_ms = 500; # Delay before auto-show triggers
          };
        };
      };
    };
  };

  # Configure blink.cmp to use NvChad's blink config and base46 highlights
  # Also add LazyVim-style Tab key handling for snippets
  # This runs after blink-cmp is set up by nvf
  luaConfigRC.blink-cmp-nvchad-config = ''
    -- Load base46 blink highlights and apply NvChad's blink config
    vim.defer_fn(function()
      -- Load base46 blink highlights
      if vim.g.base46_cache then
        pcall(dofile, vim.g.base46_cache .. "blink")
      end

      -- Try to get NvChad blink config and merge it with setupOpts
      local ok, nvchad_blink_config = pcall(require, "nvchad.blink.config")
      if ok and nvchad_blink_config then
        -- Merge NvChad's config (especially the menu config)
        local blink = require("blink.cmp")
        if blink and blink._config then
          -- Update menu config from NvChad
          if nvchad_blink_config.completion and nvchad_blink_config.completion.menu then
            blink._config.completion = blink._config.completion or {}
            blink._config.completion.menu = nvchad_blink_config.completion.menu
          end
        end
      end

      -- Set Tab keymap AFTER setup (like LazyVim does in blink.lua line 125-139)
      -- This ensures it overrides any preset defaults that might add select_next
      -- Tab should ONLY handle snippet navigation, NOT menu navigation
      local blink = require("blink.cmp")
      if blink and blink._config then
        -- Override Tab to ONLY do snippet_forward (no menu navigation, no fallback)
        -- This matches LazyVim's approach but without AI actions
        -- LazyVim does: opts.keymap["<Tab>"] = { LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" }), "fallback" }
        -- We only want snippet_forward, no AI, no fallback to menu navigation
        blink._config.keymap["<Tab>"] = {
          "snippet_forward",
        }
        -- Override Shift+Tab to ONLY do snippet_backward (no menu navigation, no fallback)
        blink._config.keymap["<S-Tab>"] = {
          "snippet_backward",
        }
      end
    end, 0)
  '';
}
