# UI enhancements (filetree, statusline, tabline, theme, snacks explorer, etc.)
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # UI features
  # Disable nvim-tree in favor of snacks explorer (configured in snacks.nix)
  filetree = {
    nvimTree.enable = false;
  };

  # Add NUI (UI component library) - required by many plugins
  # NUI is available in nvf as "nui-nvim" but doesn't have a module yet
  startPlugins = ["nui-nvim"];

  # Mini.icons configuration (LazyVim-style)
  # Provides icons and mocks nvim-web-devicons
  mini = {
    icons = {
      enable = true;
      # LazyVim-style mini.icons configuration
      setupOpts = {
        file = {
          ".keep" = {
            glyph = "󰊢";
            hl = "MiniIconsGrey";
          };
          "devcontainer.json" = {
            glyph = "";
            hl = "MiniIconsAzure";
          };
        };
        filetype = {
          dotenv = {
            glyph = "";
            hl = "MiniIconsYellow";
          };
        };
      };
    };
  };

  # Bufferline configuration (LazyVim-style)
  # Matching LazyVim's exact configuration
  tabline = {
    nvimBufferline = {
      enable = true;
      setupOpts = {
        options = {
          # Use buffers mode (LazyVim default - doesn't explicitly set mode)
          # Bufferline groups work in buffers mode - buffers are automatically grouped by directory
          # Disable buffer numbers (nvf default shows "buffer_id·ordinal", LazyVim doesn't show numbers)
          numbers = "none";
          # Use Snacks.bufdelete for closing buffers (LazyVim uses this)
          close_command = lib.generators.mkLuaInline "function(n) require('snacks').bufdelete(n) end";
          right_mouse_command = lib.generators.mkLuaInline "function(n) require('snacks').bufdelete(n) end";
          # Diagnostics from LSP
          diagnostics = "nvim_lsp";
          # Don't always show bufferline (nvf default is true, LazyVim uses false)
          always_show_bufferline = false;
          # LazyVim-style diagnostics indicator (only shows error and warning, not hint/info)
          diagnostics_indicator = lib.generators.mkLuaInline ''
            function(_, _, diag)
              -- Use LazyVim-style icons (matching LazyVim.config.icons.diagnostics)
              local icons = {
                Error = " ",
                Warn = " ",
              }
              local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                .. (diag.warning and icons.Warn .. diag.warning or "")
              return vim.trim(ret)
            end
          '';
          # Offsets matching LazyVim (neo-tree with text/highlight, snacks_layout_box minimal)
          offsets = [
            {
              filetype = "neo-tree";
              text = "Neo-tree";
              highlight = "Directory";
              text_align = "left";
            }
            {
              filetype = "snacks_layout_box";
            }
          ];
          # Get element icon - LazyVim returns LazyVim.config.icons.ft[opts.filetype]
          # which is nil for most filetypes, so bufferline uses nvim-web-devicons automatically
          # (mocked by mini.icons, so icons will work correctly)
          get_element_icon = null;
          # Indicator style - LazyVim doesn't explicitly set this, so bufferline uses its default
          # Bufferline's default indicator creates a left-side line/icon on active tabs
          # Using "icon" style with default icon (null) to match bufferline's default behavior
          indicator = {
            style = "icon";
            icon = null; # Use bufferline's default indicator icon
          };
          # Prevent tabs from changing size when selected (match LazyVim behavior)
          # nvf defaults tab_size = 18, but LazyVim doesn't set it, so we don't set it either
          # enforce_regular_tabs = false is nvf's default, but explicitly set to match LazyVim
          enforce_regular_tabs = false;
          # Always show close icons (LazyVim default - nvf also defaults to true, but explicit for clarity)
          show_buffer_close_icons = true;
          show_close_icon = true;
          # Sort buffers - nvf defaults to "extension", but LazyVim doesn't set this
          # Use "insert_after_current" to match bufferline's default behavior (visual order)
          # This ensures Shift+H and Shift+L cycle in visual order, not by extension
          sort_by = "insert_after_current";
          # Bufferline groups disabled for now
          # groups = {
          #   options = {
          #     toggle_hidden_on_enter = true;
          #   };
          #   items = [ ... ];
          # };
        };
      };
    };
  };

  # Lualine configuration (LazyVim-style)
  # Note: LazyVim utility functions are now provided by util.nix
  # We can use _G.LazyVim.lualine.root_dir() and _G.LazyVim.lualine.pretty_path() directly

  statusline = {
    lualine = {
      enable = true;
      # Use nvf's dedicated theme option - automatically uses "catppuccin" since it's supported
      # or falls back to "auto" if theme is not supported
      theme = "auto";
      # LazyVim-style lualine configuration (exact replica from ui.lua)
      setupOpts = {
        options = {
          globalstatus = lib.generators.mkLuaInline "vim.o.laststatus == 3";
          disabled_filetypes = {
            statusline = ["dashboard" "alpha" "ministarter" "snacks_dashboard"];
          };
          # Note: LazyVim doesn't set component_separators or section_separators,
          # so it uses the theme defaults which include diagonal/curved lines
          # Theme is handled by nvf's dedicated theme option above
          # Don't override separators - let theme provide angled/slanted separators
          # nvf defaults these to empty strings, but we want theme defaults
          component_separators = null; # Use theme defaults for angled separators
          section_separators = null; # Use theme defaults for angled separators
        };
        # Override sections with LazyVim-style configuration (exact replica from ui.lua)
        sections = lib.mkForce {
          # Section A: Mode
          lualine_a = [
            "mode"
          ];
          # Section B: Branch
          lualine_b = [
            "branch"
          ];
          # Section C: Root dir, diagnostics, filetype icon, file path
          lualine_c = [
            # Root directory (using LazyVim.lualine.root_dir)
            (lib.generators.mkLuaInline "_G.LazyVim.lualine.root_dir()")
            # Diagnostics (using LazyVim-style icons)
            (lib.generators.mkLuaInline ''
              {
                "diagnostics",
                symbols = {
                  error = " ",
                  warn = " ",
                  info = " ",
                  hint = " ",
                },
              }
            '')
            # Filetype icon only
            (lib.generators.mkLuaInline ''
              {
                "filetype",
                icon_only = true,
                separator = "",
                padding = { left = 1, right = 0 },
              }
            '')
            # Pretty path (using LazyVim.lualine.pretty_path)
            (lib.generators.mkLuaInline "_G.LazyVim.lualine.pretty_path()")
          ];
          # Section X: Profiler, noice, dap, lazy updates, diff
          lualine_x = [
            # Snacks profiler status (exact match from ui.lua)
            # Note: Snacks.profiler.status() returns a table, but we need to handle when Snacks isn't loaded yet
            (lib.generators.mkLuaInline ''
              (function()
                if package.loaded.snacks and Snacks and Snacks.profiler and Snacks.profiler.status then
                  return Snacks.profiler.status()
                end
                -- Return a safe fallback that won't display anything
                return {
                  function() return "" end,
                  cond = function() return false end,
                }
              end)()
            '')
            # Noice command status
            (lib.generators.mkLuaInline ''
              {
                function() return require("noice").api.status.command.get() end,
                cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
                color = function()
                  local Snacks = require("snacks")
                  return { fg = Snacks.util.color("Statement") }
                end,
              }
            '')
            # Noice mode status
            (lib.generators.mkLuaInline ''
              {
                function() return require("noice").api.status.mode.get() end,
                cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
                color = function()
                  local Snacks = require("snacks")
                  return { fg = Snacks.util.color("Constant") }
                end,
              }
            '')
            # DAP status
            (lib.generators.mkLuaInline ''
              {
                function() return "  " .. require("dap").status() end,
                cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
                color = function()
                  local Snacks = require("snacks")
                  return { fg = Snacks.util.color("Debug") }
                end,
              }
            '')
            # Git diff
            (lib.generators.mkLuaInline ''
              {
                "diff",
                symbols = {
                  added = "󰐕 ",
                  modified = "󰏬 ",
                  removed = "󰍴 ",
                },
                source = function()
                  local gitsigns = vim.b.gitsigns_status_dict
                  if gitsigns then
                    return {
                      added = gitsigns.added,
                      modified = gitsigns.changed,
                      removed = gitsigns.removed,
                    }
                  end
                end,
              }
            '')
          ];
          # Section Y: Progress and location
          lualine_y = [
            (lib.generators.mkLuaInline ''
              {
                "progress",
                separator = " ",
                padding = { left = 1, right = 0 },
              }
            '')
            (lib.generators.mkLuaInline ''
              {
                "location",
                padding = { left = 0, right = 1 },
              }
            '')
          ];
          # Section Z: Time
          lualine_z = [
            (lib.generators.mkLuaInline ''
              {
                function()
                  return " " .. os.date("%R")
                end,
              }
            '')
          ];
        };
        # Override extensions (LazyVim-style)
        extensions = lib.mkForce ["neo-tree" "lazy" "fzf"];
      };
      # Lualine init function (runs before lualine loads, exact match from ui.lua)
      # This needs to run in the init phase, so we use luaConfigRC with entryBefore
      # Note: nvf's lualine module doesn't have an init hook, so we use luaConfigRC
    };
  };

  # Lualine init function (hides native statusline until lualine loads)
  # This must run before lualine loads, and restore laststatus after
  luaConfigRC.lualine-init = ''
    -- LazyVim-style lualine init: hide native statusline until lualine loads
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  '';

  # Restore laststatus after lualine loads (runs in lualine setupOpts)
  luaConfigRC.lualine-restore = ''
    -- Restore laststatus after lualine loads (called from setupOpts)
    -- This is handled in the setupOpts via the globalstatus option
    vim.defer_fn(function()
      vim.o.laststatus = vim.g.lualine_laststatus or 3
    end, 0)
  '';

  # Noice configuration (LazyVim-style)
  ui = {
    noice = {
      enable = true;
      # LazyVim-style noice configuration
      setupOpts = {
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
        };
        routes = [
          {
            filter = {
              event = "msg_show";
              any = [
                {find = "%d+L, %d+B";}
                {find = "; after #%d+";}
                {find = "; before #%d+";}
              ];
            };
            view = "mini";
          }
        ];
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
        };
      };
    };
  };

  # Noice init function (clear messages when filetype is lazy)
  luaConfigRC.noice-init = ''
    -- LazyVim-style noice init: clear messages when filetype is lazy
    -- This prevents noice from showing messages from before it was enabled
    -- when Lazy is installing plugins
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "lazy",
      callback = function()
        vim.cmd([[messages clear]])
      end,
    })
  '';

  # Theme configuration (Catppuccin)
  theme = {
    enable = true;
    name = "tokyonight";
    style = "moon"; # LazyVim default is mocha
    transparent = false;
  };
}
