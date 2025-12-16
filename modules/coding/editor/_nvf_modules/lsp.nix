# LSP configuration and features
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
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
      setupOpts = lib.generators.mkLuaInline ''
        {
          snippets = { preset = "luasnip" },
          cmdline = {
            enabled = true,
            keymap = {
              preset = "cmdline",
              ["<Right>"] = false,
              ["<Left>"] = false,
            },
            completion = {
              list = { selection = { preselect = false } },
              menu = {
                auto_show = function(ctx)
                  return vim.fn.getcmdtype() == ":"
                end,
              },
              ghost_text = { enabled = true },
            },
          },
          appearance = {
            nerd_font_variant = "mono", -- LazyVim uses "mono" for better alignment
          },
          fuzzy = { implementation = "prefer_rust" },
          sources = {
            default = { "lsp", "snippets", "buffer", "path" },
          },
          keymap = {
            preset = "enter", -- LazyVim uses "enter" preset (Enter to accept)
            ["<C-y>"] = { "select_and_accept" }, -- LazyVim adds C-y for select_and_accept
          },
          signature = {
            enabled = true,
          },
          completion = {
            accept = {
              -- experimental auto-brackets support (LazyVim enables this)
              auto_brackets = {
                enabled = true,
              },
            },
            menu = {
              draw = {
                treesitter = { "lsp" }, -- LazyVim enables treesitter in menu draw
              },
            },
            documentation = {
              auto_show = true, -- LazyVim enables auto-show
              auto_show_delay_ms = 200,
            },
          },
        }
      '';
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

      -- LazyVim-style Tab key handling for snippets
      -- Add Tab key mapping if not already set (for snippet navigation)
      local blink = require("blink.cmp")
      if blink and blink._config and not blink._config.keymap["<Tab>"] then
        -- For "enter" preset, Tab should handle snippets
        -- This is a simplified version - LazyVim has more complex handling for AI
        blink._config.keymap["<Tab>"] = {
          "snippet_forward",
          "fallback", -- fallback to normal Tab behavior if not in snippet
        }
      end
    end, 0)
  '';
}
