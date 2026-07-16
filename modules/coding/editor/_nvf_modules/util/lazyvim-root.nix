# LazyVim utility functions (part 2): LazyVim.root module (root detection)
# Split from ../util.nix — luaConfigPre fragment, concatenated in ../util.nix
{ lib, ... }:
{
  luaConfigPre = ''
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

  '';
}
