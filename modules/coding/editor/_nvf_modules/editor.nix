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
  };

  # LazyVim-style UI options (hide native statusline, etc.)
  options = {
    # Global statusline (required for lualine to work properly)
    laststatus = 3;
    # Disable default ruler (we have lualine)
    ruler = false;
    # Don't show mode since we have a statusline
    showmode = false;
  };

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
    {
      key = "<C-h>";
      mode = "n";
      action = "<C-w>h";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
      desc = "Go to Left Window";
    }
    {
      key = "<C-j>";
      mode = "n";
      action = "<C-w>j";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
      desc = "Go to Lower Window";
    }
    {
      key = "<C-k>";
      mode = "n";
      action = "<C-w>k";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
      desc = "Go to Upper Window";
    }
    {
      key = "<C-l>";
      mode = "n";
      action = "<C-w>l";
      noremap = false; # Allow remapping (LazyVim uses remap = true)
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
      key = "<leader>cs";
      mode = "n";
      action = "<cmd>Trouble symbols toggle<cr>";
      desc = "Symbols (Trouble)";
    }
    {
      key = "<leader>cS";
      mode = "n";
      action = "<cmd>Trouble lsp toggle<cr>";
      desc = "LSP references/definitions/... (Trouble)";
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

  # Register keybinds with which-key
  binds.whichKey.register = {
    # Window navigation (Ctrl+hjkl are registered automatically by which-key)
    # Resize windows
    "<C-Up>" = "Increase Window Height";
    "<C-Down>" = "Decrease Window Height";
    "<C-Left>" = "Decrease Window Width";
    "<C-Right>" = "Increase Window Width";
    # Buffers
    "<leader>bb" = "Switch to Other Buffer";
    "<leader>`" = "Switch to Other Buffer";
    "<leader>bd" = "Delete Buffer";
    "<leader>bo" = "Delete Other Buffers";
    "<leader>bD" = "Delete Buffer and Window";
    # Bufferline-specific
    "<leader>bp" = "Toggle Pin";
    "<leader>bP" = "Delete Non-Pinned Buffers";
    "<leader>br" = "Delete Buffers to the Right";
    "<leader>bl" = "Delete Buffers to the Left";
    "[B" = "Move buffer prev";
    "]B" = "Move buffer next";
    # Editing
    "<leader>K" = "Keywordprg";
    # Search
    "<leader>ur" = "Redraw / Clear hlsearch / Diff Update";
    # Windows
    "<leader>-" = "Split Window Below";
    "<leader>|" = "Split Window Right";
    "<leader>wd" = "Delete Window";
    # Tabs
    "<leader><tab>l" = "Last Tab";
    "<leader><tab>o" = "Close Other Tabs";
    "<leader><tab>f" = "First Tab";
    "<leader><tab><tab>" = "New Tab";
    "<leader><tab>]" = "Next Tab";
    "<leader><tab>d" = "Close Tab";
    "<leader><tab>[" = "Previous Tab";
    # Quit
    "<leader>qq" = "Quit All";
    # Terminal
    "<leader>fT" = "Terminal (cwd)";
    "<leader>ft" = "Terminal (Root Dir)";
    "<c-/>" = "Terminal (Root Dir)";
    # Format
    "<leader>cf" = "Format";
    # Diagnostics
    "<leader>cd" = "Line Diagnostics";
    "]d" = "Next Diagnostic";
    "[d" = "Prev Diagnostic";
    "]e" = "Next Error";
    "[e" = "Prev Error";
    "]w" = "Next Warning";
    "[w" = "Prev Warning";
    # Trouble
    "<leader>xx" = "Diagnostics (Trouble)";
    "<leader>xX" = "Buffer Diagnostics (Trouble)";
    "<leader>cs" = "Symbols (Trouble)";
    "<leader>cS" = "LSP references/definitions/... (Trouble)";
    "<leader>xL" = "Location List (Trouble)";
    "<leader>xQ" = "Quickfix List (Trouble)";
    # Quickfix/Location
    "<leader>xq" = "Quickfix List";
    "<leader>xl" = "Location List";
    "[q" = "Previous Trouble/Quickfix Item";
    "]q" = "Next Trouble/Quickfix Item";
    # UI/Inspect
    "<leader>fn" = "New File";
    "<leader>ui" = "Inspect Pos";
    "<leader>uI" = "Inspect Tree";
    # Noice
    "<leader>sn" = "+noice";
    "<leader>snl" = "Noice Last Message";
    "<leader>snh" = "Noice History";
    "<leader>sna" = "Noice All";
    "<leader>snd" = "Dismiss All";
    "<leader>snt" = "Noice Picker (Telescope/FzfLua)";
    "<c-f>" = "Scroll Forward";
    "<c-b>" = "Scroll Backward";
    # Todo comments (using capital T to avoid conflicts)
    "]T" = "Next Todo Comment";
    "[T" = "Previous Todo Comment";
    "<leader>xt" = "Todo (Trouble)";
    "<leader>xT" = "Todo/Fix/Fixme (Trouble)";
  };

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

  # TODO, FIXME, HACK, etc. comments highlighting and navigation
  notes = {
    todo-comments = {
      enable = true;
      # LazyVim-style todo-comments configuration
      setupOpts = {};
    };
  };



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
            max_width = [ 40 0.2 ];
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
}
