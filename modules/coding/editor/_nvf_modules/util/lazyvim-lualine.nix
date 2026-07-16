# LazyVim utility functions (part 3): LazyVim.lualine module, user commands,
# LazyVim.format, statuscolumn, LazyVim.cmp (kept together in original order —
# cmp_source is defined after cmp in the source string)
# Split from ../util.nix — luaConfigPre fragment, concatenated in ../util.nix
{ lib, ... }:
{
  luaConfigPre = ''
    -- LazyVim.lualine module (ported from lazyvim.util.lualine)
    _G.LazyVim.lualine = {}

    -- Format helper for lualine components
    function _G.LazyVim.lualine.format(component, text, hl_group)
      text = text:gsub("%%", "%%%%")
      if not hl_group or hl_group == "" then
        return text
      end
      component.hl_cache = component.hl_cache or {}
      local lualine_hl_group = component.hl_cache[hl_group]
      if not lualine_hl_group then
        local utils = require("lualine.utils.utils")
        local gui = vim.tbl_filter(function(x) return x end, {
          utils.extract_highlight_colors(hl_group, "bold") and "bold",
          utils.extract_highlight_colors(hl_group, "italic") and "italic",
        })
        lualine_hl_group = component:create_hl({
          fg = utils.extract_highlight_colors(hl_group, "fg"),
          gui = #gui > 0 and table.concat(gui, ",") or nil,
        }, "LV_" .. hl_group)
        component.hl_cache[hl_group] = lualine_hl_group
      end
      return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
    end

    -- Pretty path component for lualine
    function _G.LazyVim.lualine.pretty_path(opts)
      opts = vim.tbl_extend("force", {
        relative = "cwd",
        modified_hl = "MatchParen",
        directory_hl = "",
        filename_hl = "Bold",
        modified_sign = "",
        readonly_icon = " 󰌾 ",
        length = 3,
      }, opts or {})

      return function(self)
        local path = vim.fn.expand("%:p")
        if path == "" then
          return ""
        end

        path = _G.LazyVim.norm(path)
        local root = _G.LazyVim.root.get({ normalize = true })
        local cwd = _G.LazyVim.root.cwd()

        local norm_path = path
        if _G.LazyVim.is_win() then
          norm_path = norm_path:lower()
          root = root:lower()
          cwd = cwd:lower()
        end

        if opts.relative == "cwd" and norm_path:find(cwd, 1, true) == 1 then
          path = path:sub(#cwd + 2)
        elseif norm_path:find(root, 1, true) == 1 then
          path = path:sub(#root + 2)
        end

        local sep = package.config:sub(1, 1)
        local parts = vim.split(path, "[\\/]")

        if opts.length == 0 then
          -- keep all parts
        elseif #parts > opts.length then
          parts = { parts[1], "…", unpack(parts, #parts - opts.length + 2, #parts) }
        end

        if opts.modified_hl and vim.bo.modified then
          parts[#parts] = parts[#parts] .. opts.modified_sign
          parts[#parts] = _G.LazyVim.lualine.format(self, parts[#parts], opts.modified_hl)
        else
          parts[#parts] = _G.LazyVim.lualine.format(self, parts[#parts], opts.filename_hl)
        end

        local dir = ""
        if #parts > 1 then
          dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
          dir = _G.LazyVim.lualine.format(self, dir .. sep, opts.directory_hl)
        end

        local readonly = ""
        if vim.bo.readonly then
          readonly = _G.LazyVim.lualine.format(self, opts.readonly_icon, opts.modified_hl)
        end

        return dir .. parts[#parts] .. readonly
      end
    end

    -- Root directory component for lualine
    function _G.LazyVim.lualine.root_dir(opts)
      opts = vim.tbl_extend("force", {
        cwd = false,
        subdirectory = true,
        parent = true,
        other = true,
        icon = "󱉭 ",
        color = function()
          -- Use Snacks.util.color (Snacks is loaded early via luaConfigRC)
          local Snacks = require("snacks")
          return { fg = Snacks.util.color("Special") }
        end,
      }, opts or {})

      local function get()
        local cwd = _G.LazyVim.root.cwd()
        local root = _G.LazyVim.root.get({ normalize = true })
        local name = vim.fs.basename(root)

        if root == cwd then
          return opts.cwd and name
        elseif root:find(cwd, 1, true) == 1 then
          return opts.subdirectory and name
        elseif cwd:find(root, 1, true) == 1 then
          return opts.parent and name
        else
          return opts.other and name
        end
      end

      return {
        function()
          return (opts.icon and opts.icon .. " " or "") .. (get() or "")
        end,
        cond = function()
          return type(get()) == "string"
        end,
        color = opts.color,
      }
    end

    -- Status component helper for lualine
    function _G.LazyVim.lualine.status(icon, status)
      local colors = {
        ok = "Special",
        error = "DiagnosticError",
        pending = "DiagnosticWarn",
      }
      return {
        function()
          return icon
        end,
        cond = function()
          return status() ~= nil
        end,
        color = function()
          -- Use Snacks.util.color (Snacks is loaded early via luaConfigRC)
          local color_name = colors[status()] or colors.ok
          local Snacks = require("snacks")
          return { fg = Snacks.util.color(color_name) }
        end,
      }
    end

    -- User commands (matching LazyVim's init.lua)
    -- Note: LazyExtras and LazyHealth are less relevant in nvf since we use Nix for config,
    -- but we add them for API compatibility
    vim.api.nvim_create_user_command("LazyExtras", function()
      vim.notify("LazyExtras is not available in nvf - use Nix configuration instead", vim.log.levels.INFO)
    end, { desc = "Manage LazyVim extras (not available in nvf)" })

    vim.api.nvim_create_user_command("LazyHealth", function()
      vim.cmd([[checkhealth]])
    end, { desc = "Run :checkhealth" })

    -- LazyVim.format module (matching LazyVim's util.format)
    _G.LazyVim.format = {}

    -- formatexpr function (matching LazyVim.format.formatexpr)
    function _G.LazyVim.format.formatexpr()
      -- Check for conform.nvim first (LazyVim's default formatter)
      if pcall(require, "conform") then
        return require("conform").formatexpr()
      end
      -- Fallback to LSP formatexpr
      return vim.lsp.formatexpr({ timeout_ms = 3000 })
    end

    -- LazyVim.statuscolumn function (provided by snacks.statuscolumn)
    -- snacks.statuscolumn provides Snacks.statuscolumn.get() which returns the statuscolumn string
    -- This function is called by vim.opt.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
    _G.LazyVim.statuscolumn = function()
      -- Use snacks.statuscolumn.get() if available
      if Snacks and Snacks.statuscolumn and Snacks.statuscolumn.get then
        return Snacks.statuscolumn.get()
      end
      -- Fallback to empty string
      return ""
    end

    -- LazyVim.cmp module (matching LazyVim's util.cmp)
    _G.LazyVim.cmp = {}
    _G.LazyVim.cmp.actions = {
      -- Native Snippets
      snippet_forward = function()
        if vim.snippet.active({ direction = 1 }) then
          vim.schedule(function()
            vim.snippet.jump(1)
          end)
          return true
        end
      end,
      snippet_stop = function()
        if vim.snippet then
          vim.snippet.stop()
        end
      end,
    }

    -- LazyVim.cmp.map function (matching LazyVim's util.cmp.map)
    function _G.LazyVim.cmp.map(actions, fallback)
      return function()
        for _, name in ipairs(actions) do
          if _G.LazyVim.cmp.actions[name] then
            local ret = _G.LazyVim.cmp.actions[name]()
            if ret then
              return true
            end
          end
        end
        return type(fallback) == "function" and fallback() or fallback
      end
    end

    -- LazyVim.lualine.cmp_source helper (for lualine integration)
    function _G.LazyVim.lualine.cmp_source(name)
      return {
        function()
          local blink = require("blink.cmp")
          if blink and blink._config then
            local sources = blink._config.sources or {}
            local default = sources.default or {}
            if vim.tbl_contains(default, name) then
              return "󰘦 "
            end
          end
          return ""
        end,
        cond = function()
          local blink = require("blink.cmp")
          if blink and blink._config then
            local sources = blink._config.sources or {}
            local default = sources.default or {}
            return vim.tbl_contains(default, name)
          end
          return false
        end,
        color = function()
          return { fg = Snacks.util.color("Special") }
        end,
      }
    end
  '';
}
