# Editor enhancements (aerial, dial, harpoon, etc.)
# Returns config.vim settings directly
# Takes lib as parameter for consistency (even if not used)
{lib, ...}: {
  # Set global variables (matching LazyVim defaults)
  globals = {
    # LazyVim auto format (enabled by default)
    autoformat = true;
    # Snacks animations (enabled by default)
    snacks_animate = true;
    # LSP servers to ignore when detecting root (matching LazyVim)
    root_lsp_ignore = ["copilot"];
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
  options = {
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

  # Core LazyVim-style keymaps
  # Category 1: Navigation (better j/k, window navigation, resize)
  keymaps = [
    # Better up/down (use gj/gk for wrapped lines)
    {
      key = "j";
      mode = ["n" "x"];
      action = "v:count == 0 ? 'gj' : 'j'";
      expr = true;
      silent = true;
      desc = "Down";
    }
    {
      key = "<Down>";
      mode = ["n" "x"];
      action = "v:count == 0 ? 'gj' : 'j'";
      expr = true;
      silent = true;
      desc = "Down";
    }
    {
      key = "k";
      mode = ["n" "x"];
      action = "v:count == 0 ? 'gk' : 'k'";
      expr = true;
      silent = true;
      desc = "Up";
    }
    {
      key = "<Up>";
      mode = ["n" "x"];
      action = "v:count == 0 ? 'gk' : 'k'";
      expr = true;
      silent = true;
      desc = "Up";
    }
    # Move to window using the <ctrl> hjkl keys
    # Set basic window navigation keymaps directly (like LazyVim does)
    # The smart navigation with terminal multiplexer integration is in luaConfigRC.window-navigation
    {
      key = "<C-h>";
      mode = "n";
      action = "<C-w>h";
      desc = "Go to Left Window";
    }
    {
      key = "<C-j>";
      mode = "n";
      action = "<C-w>j";
      desc = "Go to Lower Window";
    }
    {
      key = "<C-k>";
      mode = "n";
      action = "<C-w>k";
      desc = "Go to Upper Window";
    }
    {
      key = "<C-l>";
      mode = "n";
      action = "<C-w>l";
      desc = "Go to Right Window";
    }
    # Resize window using <ctrl> arrow keys
    {
      key = "<C-Up>";
      mode = "n";
      action = "<cmd>resize +2<cr>";
      desc = "Increase Window Height";
    }
    {
      key = "<C-Down>";
      mode = "n";
      action = "<cmd>resize -2<cr>";
      desc = "Decrease Window Height";
    }
    {
      key = "<C-Left>";
      mode = "n";
      action = "<cmd>vertical resize -2<cr>";
      desc = "Decrease Window Width";
    }
    {
      key = "<C-Right>";
      mode = "n";
      action = "<cmd>vertical resize +2<cr>";
      desc = "Increase Window Width";
    }
    # Category 2: Buffers
    {
      key = "<S-h>";
      mode = "n";
      action = "<cmd>bprevious<cr>";
      desc = "Prev Buffer";
    }
    {
      key = "<S-l>";
      mode = "n";
      action = "<cmd>bnext<cr>";
      desc = "Next Buffer";
    }
    {
      key = "[b";
      mode = "n";
      action = "<cmd>bprevious<cr>";
      desc = "Prev Buffer";
    }
    {
      key = "]b";
      mode = "n";
      action = "<cmd>bnext<cr>";
      desc = "Next Buffer";
    }
    {
      key = "<leader>bb";
      mode = "n";
      action = "<cmd>e #<cr>";
      desc = "Switch to Other Buffer";
    }
    {
      key = "<leader>`";
      mode = "n";
      action = "<cmd>e #<cr>";
      desc = "Switch to Other Buffer";
    }
    {
      key = "<leader>bd";
      mode = "n";
      action = "function() require('snacks').bufdelete() end";
      lua = true;
      desc = "Delete Buffer";
    }
    {
      key = "<leader>bo";
      mode = "n";
      action = "function() require('snacks').bufdelete.other() end";
      lua = true;
      desc = "Delete Other Buffers";
    }
    {
      key = "<leader>bD";
      mode = "n";
      action = "<cmd>:bd<cr>";
      desc = "Delete Buffer and Window";
    }
    # Bufferline-specific keymaps (LazyVim-style)
    {
      key = "<leader>bp";
      mode = "n";
      action = "<cmd>BufferLineTogglePin<cr>";
      desc = "Toggle Pin";
    }
    {
      key = "<leader>bP";
      mode = "n";
      action = "<cmd>BufferLineGroupClose ungrouped<cr>";
      desc = "Delete Non-Pinned Buffers";
    }
    {
      key = "<leader>br";
      mode = "n";
      action = "<cmd>BufferLineCloseRight<cr>";
      desc = "Delete Buffers to the Right";
    }
    {
      key = "<leader>bl";
      mode = "n";
      action = "<cmd>BufferLineCloseLeft<cr>";
      desc = "Delete Buffers to the Left";
    }
    {
      key = "[B";
      mode = "n";
      action = "<cmd>BufferLineMovePrev<cr>";
      desc = "Move buffer prev";
    }
    {
      key = "]B";
      mode = "n";
      action = "<cmd>BufferLineMoveNext<cr>";
      desc = "Move buffer next";
    }
    # Category 3: Editing
    # Move Lines
    {
      key = "<A-j>";
      mode = "n";
      action = "<cmd>execute 'move .+' . v:count1<cr>==";
      desc = "Move Down";
    }
    {
      key = "<A-k>";
      mode = "n";
      action = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==";
      desc = "Move Up";
    }
    {
      key = "<A-j>";
      mode = "i";
      action = "<esc><cmd>m .+1<cr>==gi";
      desc = "Move Down";
    }
    {
      key = "<A-k>";
      mode = "i";
      action = "<esc><cmd>m .-2<cr>==gi";
      desc = "Move Up";
    }
    {
      key = "<A-j>";
      mode = "v";
      action = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv";
      desc = "Move Down";
    }
    {
      key = "<A-k>";
      mode = "v";
      action = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv";
      desc = "Move Up";
    }
    # Add undo break-points
    {
      key = ",";
      mode = "i";
      action = ",<c-g>u";
    }
    {
      key = ".";
      mode = "i";
      action = ".<c-g>u";
    }
    {
      key = ";";
      mode = "i";
      action = ";<c-g>u";
    }
    # Save file
    {
      key = "<C-s>";
      mode = ["i" "x" "n" "s"];
      action = "<cmd>w<cr><esc>";
      desc = "Save File";
    }
    # Keywordprg
    {
      key = "<leader>K";
      mode = "n";
      action = "<cmd>norm! K<cr>";
      desc = "Keywordprg";
    }
    # Better indenting
    {
      key = "<";
      mode = "x";
      action = "<gv";
    }
    {
      key = ">";
      mode = "x";
      action = ">gv";
    }
    # Commenting
    {
      key = "gco";
      mode = "n";
      action = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
      desc = "Add Comment Below";
    }
    {
      key = "gcO";
      mode = "n";
      action = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
      desc = "Add Comment Above";
    }
    # Category 4: Search
    # Clear search and stop snippet on escape
    # Note: We can't easily stop snippets without LazyVim's cmp module, so we'll just clear search
    {
      key = "<esc>";
      mode = ["i" "n" "s"];
      action = "function() vim.cmd('noh'); return '<esc>' end";
      lua = true;
      expr = true;
      desc = "Escape and Clear hlsearch";
    }
    # Clear search, diff update and redraw
    {
      key = "<leader>ur";
      mode = "n";
      action = "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>";
      desc = "Redraw / Clear hlsearch / Diff Update";
    }
    # Better n and N behavior (respect search direction)
    {
      key = "n";
      mode = "n";
      action = "'Nn'[v:searchforward].'zv'";
      expr = true;
      desc = "Next Search Result";
    }
    {
      key = "n";
      mode = "x";
      action = "'Nn'[v:searchforward]";
      expr = true;
      desc = "Next Search Result";
    }
    {
      key = "n";
      mode = "o";
      action = "'Nn'[v:searchforward]";
      expr = true;
      desc = "Next Search Result";
    }
    {
      key = "N";
      mode = "n";
      action = "'nN'[v:searchforward].'zv'";
      expr = true;
      desc = "Prev Search Result";
    }
    {
      key = "N";
      mode = "x";
      action = "'nN'[v:searchforward]";
      expr = true;
      desc = "Prev Search Result";
    }
    {
      key = "N";
      mode = "o";
      action = "'nN'[v:searchforward]";
      expr = true;
      desc = "Prev Search Result";
    }
    # Category 5: Windows
    {
      key = "<leader>-";
      mode = "n";
      action = "<C-W>s";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
      desc = "Split Window Below";
    }
    {
      key = "<leader>|";
      mode = "n";
      action = "<C-W>v";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
      desc = "Split Window Right";
    }
    {
      key = "<leader>wd";
      mode = "n";
      action = "<C-W>c";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
      desc = "Delete Window";
    }
    # Category 6: Tabs
    {
      key = "<leader><tab>l";
      mode = "n";
      action = "<cmd>tablast<cr>";
      desc = "Last Tab";
    }
    {
      key = "<leader><tab>o";
      mode = "n";
      action = "<cmd>tabonly<cr>";
      desc = "Close Other Tabs";
    }
    {
      key = "<leader><tab>f";
      mode = "n";
      action = "<cmd>tabfirst<cr>";
      desc = "First Tab";
    }
    {
      key = "<leader><tab><tab>";
      mode = "n";
      action = "<cmd>tabnew<cr>";
      desc = "New Tab";
    }
    {
      key = "<leader><tab>]";
      mode = "n";
      action = "<cmd>tabnext<cr>";
      desc = "Next Tab";
    }
    {
      key = "<leader><tab>d";
      mode = "n";
      action = "<cmd>tabclose<cr>";
      desc = "Close Tab";
    }
    {
      key = "<leader><tab>[";
      mode = "n";
      action = "<cmd>tabprevious<cr>";
      desc = "Previous Tab";
    }
    # Category 7: Quit
    {
      key = "<leader>qq";
      mode = "n";
      action = "<cmd>qa<cr>";
      desc = "Quit All";
    }
    # Category 8: Terminal
    {
      key = "<leader>fT";
      mode = "n";
      action = "function() require('snacks').terminal() end";
      lua = true;
      desc = "Terminal (cwd)";
    }
    {
      key = "<leader>ft";
      mode = "n";
      action = "function() require('snacks').terminal(nil, { cwd = vim.fn.getcwd() }) end";
      lua = true;
      desc = "Terminal (Root Dir)";
    }
    {
      key = "<c-/>";
      mode = ["n" "t"];
      action = "function() require('snacks').terminal(nil, { cwd = vim.fn.getcwd() }) end";
      lua = true;
      desc = "Terminal (Root Dir)";
    }
    {
      key = "<c-_>";
      mode = ["n" "t"];
      action = "function() require('snacks').terminal(nil, { cwd = vim.fn.getcwd() }) end";
      lua = true;
      desc = "which_key_ignore";
    }
    # Category 9: Format
    # Note: Uses LSP formatting (nvf has formatOnSave enabled in lsp.nix)
    # For a full LazyVim.format replacement, we'd need conform.nvim, but LSP formatting works for now
    {
      key = "<leader>cf";
      mode = ["n" "x"];
      action = "function() vim.lsp.buf.format({ async = false }) end";
      lua = true;
      desc = "Format";
    }
    # Category 10: Diagnostics
    {
      key = "<leader>cd";
      mode = "n";
      action = "vim.diagnostic.open_float";
      lua = true;
      desc = "Line Diagnostics";
    }
    {
      key = "]d";
      mode = "n";
      action = "function() vim.diagnostic.jump({ count = vim.v.count1, float = true }) end";
      lua = true;
      desc = "Next Diagnostic";
    }
    {
      key = "[d";
      mode = "n";
      action = "function() vim.diagnostic.jump({ count = -vim.v.count1, float = true }) end";
      lua = true;
      desc = "Prev Diagnostic";
    }
    {
      key = "]e";
      mode = "n";
      action = "function() vim.diagnostic.jump({ count = vim.v.count1, severity = vim.diagnostic.severity.ERROR, float = true }) end";
      lua = true;
      desc = "Next Error";
    }
    {
      key = "[e";
      mode = "n";
      action = "function() vim.diagnostic.jump({ count = -vim.v.count1, severity = vim.diagnostic.severity.ERROR, float = true }) end";
      lua = true;
      desc = "Prev Error";
    }
    {
      key = "]w";
      mode = "n";
      action = "function() vim.diagnostic.jump({ count = vim.v.count1, severity = vim.diagnostic.severity.WARN, float = true }) end";
      lua = true;
      desc = "Next Warning";
    }
    {
      key = "[w";
      mode = "n";
      action = "function() vim.diagnostic.jump({ count = -vim.v.count1, severity = vim.diagnostic.severity.WARN, float = true }) end";
      lua = true;
      desc = "Prev Warning";
    }
    # Category 11: Trouble
    {
      key = "<leader>xx";
      mode = "n";
      action = "<cmd>Trouble diagnostics toggle<cr>";
      desc = "Diagnostics (Trouble)";
    }
    {
      key = "<leader>xX";
      mode = "n";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
      desc = "Buffer Diagnostics (Trouble)";
    }
    {
      key = "<leader>xL";
      mode = "n";
      action = "<cmd>Trouble loclist toggle<cr>";
      desc = "Location List (Trouble)";
    }
    {
      key = "<leader>xQ";
      mode = "n";
      action = "<cmd>Trouble qflist toggle<cr>";
      desc = "Quickfix List (Trouble)";
    }
    # Category 12: Quickfix/Location List
    {
      key = "<leader>xq";
      mode = "n";
      action = "function() local success, err = pcall(function() local qf = vim.fn.getqflist({ winid = 0 }); if qf.winid ~= 0 then vim.cmd.cclose() else vim.cmd.copen() end end); if not success and err then vim.notify(err, vim.log.levels.ERROR) end end";
      lua = true;
      desc = "Quickfix List";
    }
    {
      key = "<leader>xl";
      mode = "n";
      action = "function() local success, err = pcall(function() local loc = vim.fn.getloclist(0, { winid = 0 }); if loc.winid ~= 0 then vim.cmd.lclose() else vim.cmd.lopen() end end); if not success and err then vim.notify(err, vim.log.levels.ERROR) end end";
      lua = true;
      desc = "Location List";
    }
    {
      key = "[q";
      mode = "n";
      action = "function() if require('trouble').is_open() then require('trouble').prev({ skip_groups = true, jump = true }) else local ok, err = pcall(vim.cmd.cprev); if not ok then vim.notify(err, vim.log.levels.ERROR) end end end";
      lua = true;
      desc = "Previous Trouble/Quickfix Item";
    }
    {
      key = "]q";
      mode = "n";
      action = "function() if require('trouble').is_open() then require('trouble').next({ skip_groups = true, jump = true }) else local ok, err = pcall(vim.cmd.cnext); if not ok then vim.notify(err, vim.log.levels.ERROR) end end end";
      lua = true;
      desc = "Next Trouble/Quickfix Item";
    }
    # Category 12: UI/Inspect
    {
      key = "<leader>fn";
      mode = "n";
      action = "<cmd>enew<cr>";
      desc = "New File";
    }
    {
      key = "<leader>ui";
      mode = "n";
      action = "vim.show_pos";
      lua = true;
      desc = "Inspect Pos";
    }
    {
      key = "<leader>uI";
      mode = "n";
      action = "function() vim.treesitter.inspect_tree(); vim.api.nvim_input('I') end";
      lua = true;
      desc = "Inspect Tree";
    }
    # Category 14: Noice
    {
      key = "<S-Enter>";
      mode = "c";
      action = "function() require('noice').redirect(vim.fn.getcmdline()) end";
      lua = true;
      desc = "Redirect Cmdline";
    }
    {
      key = "<leader>snl";
      mode = "n";
      action = "function() require('noice').cmd('last') end";
      lua = true;
      desc = "Noice Last Message";
    }
    {
      key = "<leader>snh";
      mode = "n";
      action = "function() require('noice').cmd('history') end";
      lua = true;
      desc = "Noice History";
    }
    {
      key = "<leader>sna";
      mode = "n";
      action = "function() require('noice').cmd('all') end";
      lua = true;
      desc = "Noice All";
    }
    {
      key = "<leader>snd";
      mode = "n";
      action = "function() require('noice').cmd('dismiss') end";
      lua = true;
      desc = "Dismiss All";
    }
    {
      key = "<leader>snt";
      mode = "n";
      action = "function() require('noice').cmd('pick') end";
      lua = true;
      desc = "Noice Picker (Telescope/FzfLua)";
    }
    # Category 15: Cheatsheet (NvChad UI)
    {
      key = "<leader>ch";
      mode = "n";
      action = "<cmd>NvCheatsheet<cr>";
      desc = "Toggle Cheatsheet";
    }
    {
      key = "<c-f>";
      mode = ["i" "n" "s"];
      action = "function() if not require('noice.lsp').scroll(4) then return '<c-f>' end end";
      lua = true;
      expr = true;
      silent = true;
      desc = "Scroll Forward";
    }
    {
      key = "<c-b>";
      mode = ["i" "n" "s"];
      action = "function() if not require('noice.lsp').scroll(-4) then return '<c-b>' end end";
      lua = true;
      expr = true;
      silent = true;
      desc = "Scroll Backward";
    }
    # Category 15: Lua Debug
    # Note: Requires snacks.debug module (part of snacks.nvim)
    # This is filetype-specific, so we'll use luaConfigRC for it

    {
      key = "<leader>xt";
      mode = "n";
      action = "<cmd>Trouble todo toggle<cr>";
      desc = "Todo (Trouble)";
    }
    {
      key = "<leader>xT";
      mode = "n";
      action = "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>";
      desc = "Todo/Fix/Fixme (Trouble)";
    }
  ];

  # Lua debug keymap (filetype-specific, must use luaConfigRC)
  # Note: Requires snacks.debug module (part of snacks.nvim)
  luaConfigRC.lua-debug-keymap = ''
    -- Set up filetype-specific keymap for lua files
    -- Uses Snacks.debug.run() for running Lua code
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "lua",
      callback = function()
        if Snacks and Snacks.debug and Snacks.debug.run then
          vim.keymap.set({ "n", "x" }, "<localleader>r", function()
            Snacks.debug.run()
          end, { desc = "Run Lua", buffer = true })
        end
      end,
    })
  '';

  # Window navigation keymaps with terminal multiplexer integration
  # This ensures seamless navigation between Neovim windows and terminal multiplexer panes
  # If there's no Neovim window in a direction, the key is passed to the multiplexer
  #
  # Set these keymaps on VeryLazy event to match LazyVim's timing
  luaConfigRC.window-navigation = ''
    -- Smart window navigation that passes keys to terminal multiplexer when no window exists
    -- This matches the behavior of vim-tmux-navigator and similar plugins
    local function navigate(direction)
      local cur_win = vim.api.nvim_get_current_win()
      local cur_win_nr = vim.fn.winnr()

      -- Check if there's a window in this direction
      -- winnr(direction) returns the window number in that direction, or 0 if none
      local target_win_nr = vim.fn.winnr(direction)
      local has_window = target_win_nr ~= 0 and target_win_nr ~= cur_win_nr

      if not has_window then
        -- No window in this direction, immediately pass to terminal
        -- No window in this direction, try to pass to terminal multiplexer
        -- First, check if we're in a snacks explorer or picker that might be blocking
        local buf_type = vim.bo[cur_buf].buftype
        local filetype = vim.bo[cur_buf].filetype

        -- If we're in snacks explorer/picker, we should still try to navigate out
        -- But we need to send the key to the terminal, not just feedkeys

        -- Map direction to key sequence
        local key_seq = direction == "h" and "h" or
                        direction == "j" and "j" or
                        direction == "k" and "k" or
                        direction == "l" and "l" or nil

        if key_seq then
          -- Check for tmux
          if vim.env.TMUX then
            -- Send Ctrl+key to tmux
            -- tmux expects the key in a specific format
            local tmux_key = "C-" .. key_seq
            local pane = vim.fn.expand("$TMUX_PANE")
            if pane and pane ~= "" then
              vim.fn.systemlist({"tmux", "send-keys", "-t", pane, tmux_key})
            else
              vim.fn.systemlist({"tmux", "send-keys", tmux_key})
            end
            return
          end

          -- Check for zellij
          -- When in Zellij, send the key to the terminal so Zellij can handle navigation
          if vim.env.ZELLIJ then
            local term_key = vim.api.nvim_replace_termcodes("<C-" .. key_seq .. ">", true, false, true)
            -- Use feedkeys to send the key - it should reach Zellij
            vim.api.nvim_feedkeys(term_key, "n", false)
            return
          end

          -- For opencode or other multiplexers, we need to send the key to the terminal
          -- Since we can't directly send keys to the parent terminal from Neovim,
          -- we need to use a workaround. The best approach is to use feedkeys with
          -- 't' mode (terminal mode) which should pass the key to the terminal.
          -- However, this only works if we're in a terminal buffer.
          -- For normal buffers, we need to use a different method.

          -- Try to use feedkeys with 't' mode first (for terminal buffers)
          -- For non-terminal buffers, we'll use 'n' mode and hope the terminal catches it
          local term_key = vim.api.nvim_replace_termcodes("<C-" .. key_seq .. ">", true, false, true)

          -- Check if we're in a terminal buffer
          if vim.bo[cur_buf].buftype == "terminal" then
            -- In terminal buffer, use 't' mode to send to terminal
            vim.api.nvim_feedkeys(term_key, "t", false)
          else
            -- For non-terminal buffers (like snacks explorer), we need a different approach
            -- Use feedkeys with 'n' mode and let it propagate
            -- The key should eventually reach the terminal if no window exists
            vim.api.nvim_feedkeys(term_key, "n", false)
          end
        end
        return
      end

      -- There is a window in this direction, navigate to it
      vim.cmd("wincmd " .. direction)
    end

    -- Set up keymaps immediately (like LazyVim does)
    -- First set basic window navigation keymaps directly
    vim.keymap.set("n", "<C-h>", function() navigate("h") end, { desc = "Go to Left Window", remap = true, silent = true })
    vim.keymap.set("n", "<C-j>", function() navigate("j") end, { desc = "Go to Lower Window", remap = true, silent = true })
    vim.keymap.set("n", "<C-k>", function() navigate("k") end, { desc = "Go to Upper Window", remap = true, silent = true })
    vim.keymap.set("n", "<C-l>", function() navigate("l") end, { desc = "Go to Right Window", remap = true, silent = true })

    -- Also set them on VeryLazy event to override any plugin bindings that might conflict
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        if Snacks and Snacks.keymap then
          -- Check for lazy key handlers (like LazyVim's safe_keymap_set does)
          local keys = require("lazy.core.handler").handlers.keys
          local function should_set(lhs, mode)
            if keys and keys.have and keys:have(lhs, mode) then
              return false
            end
            return true
          end

          -- Set keymaps with smart navigation (override if needed)
          if should_set("<C-h>", "n") then
            Snacks.keymap.set("n", "<C-h>", function() navigate("h") end, { desc = "Go to Left Window", silent = true })
          end
          if should_set("<C-j>", "n") then
            Snacks.keymap.set("n", "<C-j>", function() navigate("j") end, { desc = "Go to Lower Window", silent = true })
          end
          if should_set("<C-k>", "n") then
            Snacks.keymap.set("n", "<C-k>", function() navigate("k") end, { desc = "Go to Upper Window", silent = true })
          end
          if should_set("<C-l>", "n") then
            Snacks.keymap.set("n", "<C-l>", function() navigate("l") end, { desc = "Go to Right Window", silent = true })
          end
        end
      end,
    })
  '';

  # TODO, FIXME, HACK, etc. comments highlighting and navigation
  notes = {
    todo-comments = {
      enable = true;
      # LazyVim-style todo-comments configuration
      setupOpts = {};
    };
  };

  mini.files.enable = true;

  # Code outline and symbols
  utility = {
    outline = {
      aerial-nvim = {
        enable = true;
        # LazyVim-style aerial configuration
        setupOpts = {
          # optionally use on_attach to set keymaps when aerial has attached to a buffer
          on_attach = lib.generators.mkLuaInline ''
            function(bufnr)
              -- Jump to the previous/next item in the current buffer
              vim.keymap.set("n", "[a", "<cmd>AerialPrev<CR>", { buffer = bufnr })
              vim.keymap.set("n", "]a", "<cmd>AerialNext<CR>", { buffer = bufnr })
            end
          '';
          # automatically open aerial when entering supported buffer
          open_automatic = false;
          # Set to true to have aerial open when you open certain filetypes
          open_automatic_min_lines = 0;
          # Set to true to have aerial open when you open certain filetypes
          open_automatic_min_symbols = 0;
          layout = {
            # These control the width of the aerial window.
            # They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
            # min_width and max_width can be a list of mixed types.
            max_width = [40 0.2];
            width = null;
            min_width = 10;
            # key-value pairs of window-local options for aerial window (e.g. wrap, number, etc.)
            win_opts = {};
            # Determines the default direction to open the aerial window. The 'prefer'
            # options will open the window in the other direction *if* there is a
            # different buffer in the way of the preferred direction
            default_direction = "prefer_right";
            # Determines where the aerial window will be opened
            placement = "window";
          };
        };
        mappings = {
          toggle = "<leader>cs";
        };
      };
    };
  };

  # LazyVim-style autocommand groups
  augroups = [
    {
      name = "lazyvim_checktime";
      clear = true;
    }
    {
      name = "lazyvim_highlight_yank";
      clear = true;
    }
    {
      name = "lazyvim_resize_splits";
      clear = true;
    }
    {
      name = "lazyvim_last_loc";
      clear = true;
    }
    {
      name = "lazyvim_close_with_q";
      clear = true;
    }
    {
      name = "lazyvim_man_unlisted";
      clear = true;
    }
    {
      name = "lazyvim_wrap_spell";
      clear = true;
    }
    {
      name = "lazyvim_json_conceal";
      clear = true;
    }
    {
      name = "lazyvim_auto_create_dir";
      clear = true;
    }
  ];

  # LazyVim-style autocommands
  autocmds = [
    # Check if we need to reload the file when it changed
    {
      event = ["FocusGained" "TermClose" "TermLeave"];
      group = "lazyvim_checktime";
      desc = "Check if file changed externally";
      callback = lib.generators.mkLuaInline ''
        function()
          if vim.o.buftype ~= "nofile" then
            vim.cmd("checktime")
          end
        end
      '';
    }
    # Highlight on yank
    {
      event = ["TextYankPost"];
      group = "lazyvim_highlight_yank";
      desc = "Highlight yanked text";
      callback = lib.generators.mkLuaInline ''
        function()
          (vim.hl or vim.highlight).on_yank()
        end
      '';
    }
    # Resize splits if window got resized
    {
      event = ["VimResized"];
      group = "lazyvim_resize_splits";
      desc = "Resize splits when window resized";
      callback = lib.generators.mkLuaInline ''
        function()
          local current_tab = vim.fn.tabpagenr()
          vim.cmd("tabdo wincmd =")
          vim.cmd("tabnext " .. current_tab)
        end
      '';
    }
    # Go to last loc when opening a buffer
    {
      event = ["BufReadPost"];
      group = "lazyvim_last_loc";
      desc = "Go to last location when opening buffer";
      callback = lib.generators.mkLuaInline ''
        function(event)
          local exclude = { "gitcommit" }
          local buf = event.buf
          if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
            return
          end
          vim.b[buf].lazyvim_last_loc = true
          local mark = vim.api.nvim_buf_get_mark(buf, '"')
          local lcount = vim.api.nvim_buf_line_count(buf)
          if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end
      '';
    }
    # Close some filetypes with <q>
    {
      event = ["FileType"];
      pattern = [
        "PlenaryTestPopup"
        "checkhealth"
        "dbout"
        "gitsigns-blame"
        "grug-far"
        "help"
        "lspinfo"
        "neotest-output"
        "neotest-output-panel"
        "neotest-summary"
        "notify"
        "qf"
        "spectre_panel"
        "startuptime"
        "tsplayground"
      ];
      group = "lazyvim_close_with_q";
      desc = "Close buffer with q for specific filetypes";
      callback = lib.generators.mkLuaInline ''
        function(event)
          vim.bo[event.buf].buflisted = false
          vim.schedule(function()
            vim.keymap.set("n", "q", function()
              vim.cmd("close")
              pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
            end, {
              buffer = event.buf,
              silent = true,
              desc = "Quit buffer",
            })
          end)
        end
      '';
    }
    # Make it easier to close man-files when opened inline
    {
      event = ["FileType"];
      pattern = ["man"];
      group = "lazyvim_man_unlisted";
      desc = "Unlist man buffers";
      callback = lib.generators.mkLuaInline ''
        function(event)
          vim.bo[event.buf].buflisted = false
        end
      '';
    }
    # Wrap and check for spell in text filetypes
    {
      event = ["FileType"];
      pattern = ["text" "plaintex" "typst" "gitcommit" "markdown"];
      group = "lazyvim_wrap_spell";
      desc = "Enable wrap and spell for text filetypes";
      callback = lib.generators.mkLuaInline ''
        function()
          vim.opt_local.wrap = true
          vim.opt_local.spell = true
        end
      '';
    }
    # Fix conceallevel for json files
    {
      event = ["FileType"];
      pattern = ["json" "jsonc" "json5"];
      group = "lazyvim_json_conceal";
      desc = "Disable conceal for json files";
      callback = lib.generators.mkLuaInline ''
        function()
          vim.opt_local.conceallevel = 0
        end
      '';
    }
    # Auto create dir when saving a file
    {
      event = ["BufWritePre"];
      group = "lazyvim_auto_create_dir";
      desc = "Auto create directory when saving file";
      callback = lib.generators.mkLuaInline ''
        function(event)
          if event.match:match("^%w%w+:[\\/][\\/]") then
            return
          end
          local file = vim.uv.fs_realpath(event.match) or event.match
          vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
        end
      '';
    }
  ];
}
