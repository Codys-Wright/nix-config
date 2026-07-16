# LazyVim utility functions (part 1): nvim-web-devicons mock, LazyVim namespace,
# config/icons, kind filter, path helpers
# Split from ../util.nix — luaConfigPre fragment, concatenated in ../util.nix
{ lib, ... }:
{
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

  '';
}
