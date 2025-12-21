# AI assistants and AI-powered features
# Based on LazyVim's AI extras
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{
  lib,
  nvf ? null,
  ...
}: {
  # Enable GitHub Copilot AI autocompletion
  # Configured to work with blink.cmp (similar to LazyVim)
  assistant = {
    copilot = {
      enable = false; # Disabled - removed AI integration
      # Disable nvim-cmp integration since we're using blink.cmp
      # blink.cmp integration is configured separately in lsp.nix
      cmp.enable = false;
      # Configure copilot to work with blink.cmp
      # Disable inline suggestions since we're using cmp
      setupOpts = {
        suggestion = {
          enabled = false; # Disable inline suggestions, use blink.cmp instead
          auto_trigger = true;
          hide_during_completion = true; # Hide during blink.cmp completion
          keymap = {
            accept = false; # Handled by blink.cmp
            next = "<M-]>";
            prev = "<M-[>";
          };
        };
        panel = {
          enabled = false; # Disable panel, use blink.cmp
        };
        filetypes = {
          markdown = true;
          help = true;
        };
      };
    };
  };

  # Note: blink.cmp integration for copilot is configured in lsp.nix
  # The copilot source is added to blink.cmp's sources.default and sources.providers

  # Additional sidekick integrations (matching LazyVim's sidekick.lua)
  luaConfigRC.sidekick-integrations = ''
    -- Copilot LSP server configuration (if sidekick NES is enabled)
    -- This matches LazyVim's nvim-lspconfig opts extension
    vim.defer_fn(function()
      local sk = require("sidekick")
      if sk and sk.config and sk.config.nes and sk.config.nes.enabled ~= false then
        -- Add copilot server to LSP config if not already present
        local lspconfig = require("lspconfig")
        if lspconfig and not lspconfig.configs.copilot then
          -- Copilot server will be configured elsewhere, just ensure it's available
        end
      end
    end, 100)

    -- Lualine integration (matching LazyVim's sidekick.lua)
    -- Add sidekick status components to lualine_x
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        local lualine = require("lualine")
        if lualine and lualine.setup then
          local icons = {
            Error = { "󰅚 ", "DiagnosticError" },
            Inactive = { "󰅚 ", "MsgArea" },
            Warning = { "󰀪 ", "DiagnosticWarn" },
            Normal = { _G.LazyVim.config.icons.kinds.Copilot or "󰘦 ", "Special" },
          }
          
          -- Get current lualine config
          local config = lualine.get_config()
          if config and config.sections and config.sections.lualine_x then
            -- Insert sidekick status component at position 2 (matching LazyVim)
            table.insert(config.sections.lualine_x, 2, {
              function()
                local status = require("sidekick.status").get()
                return status and vim.tbl_get(icons, status.kind, 1)
              end,
              cond = function()
                return require("sidekick.status").get() ~= nil
              end,
              color = function()
                local status = require("sidekick.status").get()
                local hl = status and (status.busy and "DiagnosticWarn" or vim.tbl_get(icons, status.kind, 2))
                return { fg = Snacks.util.color(hl) }
              end,
            })

            -- Insert sidekick CLI component at position 2 (matching LazyVim)
            table.insert(config.sections.lualine_x, 2, {
              function()
                local status = require("sidekick.status").cli()
                return "󰅚 " .. (#status > 1 and #status or "")
              end,
              cond = function()
                return #require("sidekick.status").cli() > 0
              end,
              color = function()
                return { fg = Snacks.util.color("Special") }
              end,
            })

            -- Reload lualine with updated config
            lualine.setup(config)
          end
        end
      end,
    })

    -- Snacks picker integration (matching LazyVim's sidekick.lua)
    -- Add sidekick_send action and <a-a> keymap to snacks picker
    vim.defer_fn(function()
      if Snacks and Snacks.config and Snacks.config.picker then
        -- Add sidekick_send action
        if not Snacks.config.picker.actions then
          Snacks.config.picker.actions = {}
        end
        Snacks.config.picker.actions.sidekick_send = function(...)
          return require("sidekick.cli.picker.snacks").send(...)
        end

        -- Add <a-a> keymap to snacks picker input
        if not Snacks.config.picker.win then
          Snacks.config.picker.win = {}
        end
        if not Snacks.config.picker.win.input then
          Snacks.config.picker.win.input = {}
        end
        if not Snacks.config.picker.win.input.keys then
          Snacks.config.picker.win.input.keys = {}
        end
        Snacks.config.picker.win.input.keys["<a-a>"] = {
          "sidekick_send",
          mode = { "n", "i" },
        }
      end
    end, 200)
  '';

  # Sidekick plugin configuration
  # Sidekick provides next edit suggestions and CLI integration
  extraPlugins = {
    sidekick = {
      # Package is passed from nvf.nix (from nixpkgs)
      # package will be set in nvf.nix
      setup = ''
        require("sidekick").setup({
          cli = {
            mux = {
              backend = "zellij",
              enabled = true,
            },
          },
        })
        
        -- Accept inline suggestions or next edits (matching LazyVim)
        if _G.LazyVim and _G.LazyVim.cmp then
          _G.LazyVim.cmp.actions.ai_nes = function()
            local Nes = require("sidekick.nes")
            if Nes.have() and (Nes.jump() or Nes.apply()) then
              return true
            end
          end
        end
        
        -- Snacks toggle for Sidekick NES
        if Snacks and Snacks.toggle then
          Snacks.toggle({
            name = "Sidekick NES",
            get = function()
              return require("sidekick.nes").enabled
            end,
            set = function(state)
              require("sidekick.nes").enable(state)
            end,
          }):map("<leader>uN")
        end
      '';
    };
  };

  # Sidekick keymaps (matching LazyVim's sidekick.lua)
  keymaps = [
    # <tab> in normal mode with LazyVim.cmp.map (matching LazyVim)
    {
      key = "<tab>";
      mode = "n";
      action = "function() if _G.LazyVim and _G.LazyVim.cmp and _G.LazyVim.cmp.map then return _G.LazyVim.cmp.map({ 'ai_nes' }, '<tab>')() else return '<Tab>' end end";
      lua = true;
      expr = true;
      desc = "Goto/Apply Next Edit Suggestion";
    }
    # <tab> in insert mode (fallback for compatibility)
    {
      key = "<tab>";
      mode = "i";
      action = "function() if not require('sidekick').nes_jump_or_apply() then return '<Tab>' end end";
      lua = true;
      expr = true;
      desc = "Goto/Apply Next Edit Suggestion";
    }
    # <leader>a group definition (matching LazyVim)
    {
      key = "<leader>a";
      mode = ["n" "v"];
      action = "";
      desc = "+ai";
    }
    {
      key = "<c-.>";
      mode = ["n" "t" "i" "x"];
      action = "function() require('sidekick.cli').toggle() end";
      lua = true;
      desc = "Sidekick Toggle";
    }
    {
      key = "<leader>aa";
      mode = "n";
      action = "function() require('sidekick.cli').toggle() end";
      lua = true;
      desc = "Sidekick Toggle CLI";
    }
    {
      key = "<leader>as";
      mode = "n";
      action = "function() require('sidekick.cli').select() end";
      lua = true;
      desc = "Select CLI";
    }
    {
      key = "<leader>ad";
      mode = "n";
      action = "function() require('sidekick.cli').close() end";
      lua = true;
      desc = "Detach a CLI Session";
    }
    {
      key = "<leader>at";
      mode = ["x" "n"];
      action = "function() require('sidekick.cli').send({ msg = '{this}' }) end";
      lua = true;
      desc = "Send This";
    }
    {
      key = "<leader>af";
      mode = "n";
      action = "function() require('sidekick.cli').send({ msg = '{file}' }) end";
      lua = true;
      desc = "Send File";
    }
    {
      key = "<leader>av";
      mode = "x";
      action = "function() require('sidekick.cli').send({ msg = '{selection}' }) end";
      lua = true;
      desc = "Send Visual Selection";
    }
    {
      key = "<leader>ap";
      mode = ["n" "x"];
      action = "function() require('sidekick.cli').prompt() end";
      lua = true;
      desc = "Sidekick Select Prompt";
    }
    {
      key = "<leader>ac";
      mode = "n";
      action = "function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end";
      lua = true;
      desc = "Sidekick Toggle Claude";
    }
  ];

  # Available AI assistants in nvf:
  # - copilot (GitHub Copilot) ✓ ENABLED
  # - avante (Avante AI assistant)
  # - supermaven-nvim (Supermaven AI autocompletion)
  # - chatgpt (ChatGPT AI assistant)
  # - codecompanion (CodeCompanion AI assistant)
  # - sidekick (Sidekick for next edit suggestions) ✓ ENABLED
  #
  # Missing from LazyVim's list (would need to be added):
  # - codeium (Codeium AI autocompletion)
  # - claudecode (Claude Code AI assistant)
  # - copilot-chat (CopilotChat for chatting)
  # - copilot-native (Native Copilot LSP - Neovim 0.12+)
  # - tabnine (TabNine AI autocompletion)
}
