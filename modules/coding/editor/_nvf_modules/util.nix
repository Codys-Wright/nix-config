# LazyVim utility functions ported to nvf
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Add plenary.nvim as a start plugin (common dependency for many Lua plugins)
  startPlugins = ["plenary-nvim"];

  # Port LazyVim utility functions via luaConfigPre
  # These functions are used throughout the config (lualine, root detection, etc.)
  # luaConfigPre runs before the DAG, ensuring _G.LazyVim is available when plugins load
  luaConfigPre = ''
    -- LazyVim-style mini.icons init: mock nvim-web-devicons
    -- This must run before any plugin tries to load nvim-web-devicons
    -- This allows mini.icons to replace nvim-web-devicons transparently
    package.preload["nvim-web-devicons"] = function()
      require("mini.icons").mock_nvim_web_devicons()
      return package.loaded["nvim-web-devicons"]
    end

    -- LazyVim utility functions (ported from LazyVim)
    -- These provide the same API as LazyVim.util for compatibility
    -- Loaded via luaConfigPre to ensure availability before plugins load

    -- Create LazyVim namespace if it doesn't exist
    if not _G.LazyVim then
      _G.LazyVim = {}
    end

    -- LazyVim.config (matching LazyVim's init.lua)
    _G.LazyVim.config = {}
    _G.LazyVim.config.version = "15.13.0"

    -- Icons configuration (matching LazyVim.config.icons)
    _G.LazyVim.config.icons = {
      misc = {
        dots = "󰇘",
      },
      ft = {
        octo = " ",
        gh = " ",
        ["markdown.gh"] = " ",
      },
      dap = {
        Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
        Breakpoint = " ",
        BreakpointCondition = " ",
        BreakpointRejected = { " ", "DiagnosticError" },
        LogPoint = ".>",
      },
      diagnostics = {
        Error = " ",
        Warn = " ",
        Hint = " ",
        Info = " ",
      },
      git = {
        added = " ",
        modified = " ",
        removed = " ",
      },
      kinds = {
        Array = " ",
        Boolean = "󰨙 ",
        Class = " ",
        Codeium = "󰘦 ",
        Color = " ",
        Control = " ",
        Collapsed = " ",
        Constant = "󰏿 ",
        Constructor = " ",
        Copilot = " ",
        Enum = " ",
        EnumMember = " ",
        Event = " ",
        Field = " ",
        File = " ",
        Folder = " ",
        Function = "󰊕 ",
        Interface = " ",
        Key = " ",
        Keyword = " ",
        Method = "󰊕 ",
        Module = " ",
        Namespace = "󰦮 ",
        Null = " ",
        Number = "󰎠 ",
        Object = " ",
        Operator = " ",
        Package = " ",
        Property = " ",
        Reference = " ",
        Snippet = "󱄽 ",
        String = " ",
        Struct = "󰆼 ",
        Supermaven = " ",
        TabNine = "󰏚 ",
        Text = " ",
        TypeParameter = " ",
        Unit = " ",
        Value = " ",
        Variable = "󰀫 ",
      },
    }

    -- Kind filter configuration (matching LazyVim.config.kind_filter)
    _G.LazyVim.config.kind_filter = {
      default = {
        "Class",
        "Constructor",
        "Enum",
        "Field",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Package",
        "Property",
        "Struct",
        "Trait",
      },
      markdown = false,
      help = false,
      lua = {
        "Class",
        "Constructor",
        "Enum",
        "Field",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Property",
        "Struct",
        "Trait",
      },
    }

    -- Get kind filter for a buffer (matching LazyVim.get_kind_filter)
    function _G.LazyVim.get_kind_filter(buf)
      buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
      local ft = vim.bo[buf].filetype
      if _G.LazyVim.config.kind_filter == false then
        return
      end
      if _G.LazyVim.config.kind_filter[ft] == false then
        return
      end
      if type(_G.LazyVim.config.kind_filter[ft]) == "table" then
        return _G.LazyVim.config.kind_filter[ft]
      end
      return type(_G.LazyVim.config.kind_filter) == "table" and type(_G.LazyVim.config.kind_filter.default) == "table" and _G.LazyVim.config.kind_filter.default or nil
    end

    -- Helper: normalize paths (replicates lazy.core.util.norm)
    -- Uses vim.fs.normalize which is the Neovim built-in
    function _G.LazyVim.norm(path)
      return vim.fs.normalize(path)
    end

    -- Helper: check if Windows
    function _G.LazyVim.is_win()
      return vim.uv.os_uname().sysname:find("Windows") ~= nil
    end

    -- LazyVim.root module (ported from lazyvim.util.root)
    _G.LazyVim.root = {}

    -- Root detection spec (default: LSP, .git/lua patterns, cwd)
    _G.LazyVim.root.spec = { "lsp", { ".git", "lua" }, "cwd" }
    _G.LazyVim.root.cache = {}
    _G.LazyVim.root.detectors = {}

    -- Get buffer path
    function _G.LazyVim.root.bufpath(buf)
      return _G.LazyVim.root.realpath(vim.api.nvim_buf_get_name(assert(buf)))
    end

    -- Get real path (normalized)
    function _G.LazyVim.root.realpath(path)
      if path == "" or path == nil then
        return nil
      end
      -- On non-Windows, use fs_realpath; on Windows, just normalize
      path = vim.fn.has("win32") == 0 and vim.uv.fs_realpath(path) or path
      return _G.LazyVim.norm(path)
    end

    -- Get current working directory (normalized)
    function _G.LazyVim.root.cwd()
      return _G.LazyVim.root.realpath(vim.uv.cwd()) or ""
    end

    -- CWD detector
    function _G.LazyVim.root.detectors.cwd()
      return { vim.uv.cwd() }
    end

    -- LSP detector
    function _G.LazyVim.root.detectors.lsp(buf)
      local bufpath = _G.LazyVim.root.bufpath(buf)
      if not bufpath then
        return {}
      end
      local roots = {}
      local clients = vim.lsp.get_clients({ bufnr = buf })
      local root_lsp_ignore = vim.g.root_lsp_ignore or {}
      clients = vim.tbl_filter(function(client)
        return not vim.tbl_contains(root_lsp_ignore, client.name)
      end, clients)
      for _, client in pairs(clients) do
        local workspace = client.config.workspace_folders
        for _, ws in pairs(workspace or {}) do
          roots[#roots + 1] = vim.uri_to_fname(ws.uri)
        end
        if client.root_dir then
          roots[#roots + 1] = client.root_dir
        end
      end
      return vim.tbl_filter(function(path)
        path = _G.LazyVim.norm(path)
        return path and bufpath:find(path, 1, true) == 1
      end, roots)
    end

    -- Pattern detector (for .git, lua, etc.)
    function _G.LazyVim.root.detectors.pattern(buf, patterns)
      patterns = type(patterns) == "string" and { patterns } or patterns
      local path = _G.LazyVim.root.bufpath(buf) or vim.uv.cwd()
      local pattern = vim.fs.find(function(name)
        for _, p in ipairs(patterns) do
          if name == p then
            return true
          end
          if p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$") then
            return true
          end
        end
        return false
      end, { path = path, upward = true })[1]
      return pattern and { vim.fs.dirname(pattern) } or {}
    end

    -- Resolve spec to detector function
    function _G.LazyVim.root.resolve(spec)
      if _G.LazyVim.root.detectors[spec] then
        return _G.LazyVim.root.detectors[spec]
      elseif type(spec) == "function" then
        return spec
      end
      return function(buf)
        return _G.LazyVim.root.detectors.pattern(buf, spec)
      end
    end

    -- Detect root directory
    function _G.LazyVim.root.detect(opts)
      opts = opts or {}
      opts.spec = opts.spec or (type(vim.g.root_spec) == "table" and vim.g.root_spec or _G.LazyVim.root.spec)
      opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

      local ret = {}
      for _, spec in ipairs(opts.spec) do
        local paths = _G.LazyVim.root.resolve(spec)(opts.buf)
        paths = paths or {}
        paths = type(paths) == "table" and paths or { paths }
        local roots = {}
        for _, p in ipairs(paths) do
          local pp = _G.LazyVim.root.realpath(p)
          if pp and not vim.tbl_contains(roots, pp) then
            roots[#roots + 1] = pp
          end
        end
        table.sort(roots, function(a, b)
          return #a > #b
        end)
        if #roots > 0 then
          ret[#ret + 1] = { spec = spec, paths = roots }
          if opts.all == false then
            break
          end
        end
      end
      return ret
    end

    -- Get root directory (main function)
    function _G.LazyVim.root.get(opts)
      opts = opts or {}
      local buf = opts.buf or vim.api.nvim_get_current_buf()
      local ret = _G.LazyVim.root.cache[buf]
      if not ret then
        local roots = _G.LazyVim.root.detect({ all = false, buf = buf })
        ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
        _G.LazyVim.root.cache[buf] = ret
      end
      if opts and opts.normalize then
        return ret
      end
      return _G.LazyVim.is_win() and ret:gsub("/", "\\") or ret
    end

    -- Get git root
    function _G.LazyVim.root.git()
      local root = _G.LazyVim.root.get()
      local git_root = vim.fs.find(".git", { path = root, upward = true })[1]
      local ret = git_root and vim.fn.fnamemodify(git_root, ":h") or root
      return ret
    end

    -- Setup root cache clearing
    function _G.LazyVim.root.setup()
      vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
        group = vim.api.nvim_create_augroup("lazyvim_root_cache", { clear = true }),
        callback = function(event)
          _G.LazyVim.root.cache[event.buf] = nil
        end,
      })
    end

    -- Initialize root cache clearing
    _G.LazyVim.root.setup()

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
