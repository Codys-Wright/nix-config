# Editor core options (globals, LazyVim-style opts, special-option lua, clipboard)
# Split from ../editor.nix — returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{ lib, ... }:
{
  # Set global variables (matching LazyVim defaults)
  globals = {
    # LazyVim auto format (enabled by default)
    autoformat = true;
    # Snacks animations (enabled by default)
    snacks_animate = true;
    # LSP servers to ignore when detecting root (matching LazyVim)
    root_lsp_ignore = [ "copilot" ];
    # LazyVim picker to use (not used in nvf, but set for compatibility)
    lazyvim_picker = "auto";
    # LazyVim completion engine (not used in nvf, but set for compatibility)
    lazyvim_cmp = "auto";
    # Use AI source in completion if available
    ai_cmp = true;
    # Hide deprecation warnings
    deprecation_warnings = false;
    # Show trouble symbols in lualine
    trouble_lualine = true;
    # Fix markdown indentation settings
    markdown_recommended_style = 0;
  };

  # LazyVim-style options (matching LazyVim's options.lua)
  # Note: use `opts` (not `options`) to avoid conflict with NixOS module system's reserved `options` key
  opts = {
    # Global statusline (required for lualine to work properly)
    laststatus = 3;
    # Disable default ruler (we have lualine)
    ruler = false;
    # Don't show mode since we have a statusline
    showmode = false;
    # Enable auto write
    autowrite = true;
    # Clipboard (handled separately via clipboard.enable, but set here for compatibility)
    # Note: nvf's clipboard module handles SSH detection automatically
    # completeopt = "menu,menuone,noselect" - handled by blink.cmp
    # Conceal level (hide * markup for bold/italic)
    conceallevel = 2;
    # Confirm to save changes before exiting modified buffer
    confirm = true;
    # Enable highlighting of the current line
    cursorline = true;
    # Use spaces instead of tabs
    expandtab = true;
    # Folding
    foldlevel = 99;
    foldmethod = "indent";
    foldtext = "";
    # Format options
    formatoptions = "jcroqlnt";
    # Grep settings
    grepformat = "%f:%l:%c:%m";
    grepprg = "rg --vimgrep";
    # Search settings
    ignorecase = true;
    smartcase = true;
    # Preview incremental substitute
    inccommand = "nosplit";
    # Jump options
    jumpoptions = "view";
    # Wrap lines at convenient points
    linebreak = true;
    # Show some invisible characters (tabs...)
    list = true;
    # Enable mouse mode
    mouse = "a";
    # Line numbers
    number = true;
    relativenumber = true;
    # Popup menu settings
    pumblend = 10;
    pumheight = 10;
    # Scrolling
    scrolloff = 4;
    sidescrolloff = 8;
    # Indentation
    shiftround = true;
    shiftwidth = 2;
    smartindent = true;
    tabstop = 2;
    # Short messages
    # Note: shortmess.append is handled via luaConfigRC since nvf doesn't support append directly
    # signcolumn = "yes" - handled by gitsigns
    # Smooth scrolling
    smoothscroll = true;
    # Split settings
    splitbelow = true;
    splitkeep = "screen";
    splitright = true;
    # Status column (handled by snacks.statuscolumn)
    # statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]] - set via snacks.statuscolumn
    # True color support
    termguicolors = true;
    # Timeout length (lower for which-key)
    timeoutlen = 300;
    # Undo settings
    undofile = true;
    undolevels = 10000;
    # Update time (for swap file and CursorHold)
    updatetime = 200;
    # Virtual edit (allow cursor to move where there is no text in visual block mode)
    virtualedit = "block";
    # Command-line completion mode
    wildmode = "longest:full,full";
    # Minimum window width
    winminwidth = 5;
    # Disable line wrap (default, can be toggled)
    wrap = false;
  };

  # Additional options that need special handling (via luaConfigRC)
  luaConfigRC.lazyvim-options = ''
    -- Set options that require special handling or appending
    -- formatexpr (requires LazyVim.format.formatexpr function)
    vim.opt.formatexpr = "v:lua.LazyVim.format.formatexpr()"

    -- shortmess:append (nvf doesn't support append directly)
    vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })

    -- fillchars (nvf doesn't support dict options directly)
    vim.opt.fillchars = {
      foldopen = "󰅀",
      foldclose = "󰅂",
      fold = " ",
      foldsep = " ",
      diff = "╱",
      eob = " ",
    }

    -- sessionoptions (nvf doesn't support array options directly)
    vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

    -- spelllang (nvf doesn't support array options directly)
    vim.opt.spelllang = { "en" }

    -- statuscolumn (requires LazyVim.statuscolumn function)
    -- Note: snacks.statuscolumn also sets this automatically, but we set it here for LazyVim compatibility
    -- If snacks.statuscolumn is enabled, it will override this, which is fine
    if _G.LazyVim and _G.LazyVim.statuscolumn then
      vim.opt.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
    end

    -- Set mapleader and maplocalleader (matching LazyVim)
    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"

    -- Set root_spec (matching LazyVim)
    vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
  '';

  # Clipboard integration (LazyVim-style)
  # Sync with system clipboard unless in SSH (to allow OSC 52 integration)
  clipboard = {
    enable = true;
    registers = "unnamedplus"; # Use "+ register for system clipboard
  };
}
