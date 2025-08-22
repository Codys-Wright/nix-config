{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.lazy;

  icons = {
    misc = {
      dots = "󰇘";
    };
    ft = {
      octo = "";
    };
    dap = {
      Stopped = [ "󰁕 " "DiagnosticWarn" "DapStoppedLine" ];
      Breakpoint = " ";
      BreakpointCondition = " ";
      BreakpointRejected = [ " " "DiagnosticError" ];
      LogPoint = ".>";
    };
    diagnostics = {
      Error = " ";
      Warn  = " ";
      Hint  = " ";
      Info  = " ";
    };
    git = {
      added    = " ";
      modified = " ";
      removed  = " ";
    };
    kinds = {
      Array         = " ";
      Boolean       = "󰨙 ";
      Class         = " ";
      Codeium       = "󰘦 ";
      Color         = " ";
      Control       = " ";
      Collapsed     = " ";
      Constant      = "󰏿 ";
      Constructor   = " ";
      Copilot       = " ";
      Enum          = " ";
      EnumMember    = " ";
      Event         = " ";
      Field         = " ";
      File          = " ";
      Folder        = " ";
      Function      = "󰊕 ";
      Interface     = " ";
      Key           = " ";
      Keyword       = " ";
      Method        = "󰊕 ";
      Module        = " ";
      Namespace     = "󰦮 ";
      Null          = " ";
      Number        = "󰎠 ";
      Object        = " ";
      Operator      = " ";
      Package       = " ";
      Property      = " ";
      Reference     = " ";
      Snippet       = "󱄽 ";
      String        = " ";
      Struct        = "󰆼 ";
      Supermaven    = " ";
      TabNine       = "󰏚 ";
      Text          = " ";
      TypeParameter = " ";
      Unit          = " ";
      Value         = " ";
      Variable      = "󰀫 ";
    };
  };
in
{
  options.${namespace}.coding.editor.nvim.modules.lazy = with types; {
    enable = mkBoolOpt false "Enable LazyVim-style keymaps and configuration";
  };

  config = mkIf cfg.enable {
    # Configure nvf with LazyVim-style keymaps and autocmds
    programs.nvf.settings.vim = {
      # LazyVim-style autogroups
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

      # LazyVim-style autocmds
      autocmds = [
        # Check if we need to reload the file when it changed
        {
          event = [ "FocusGained" "TermClose" "TermLeave" ];
          group = "lazyvim_checktime";
          desc = "Check for file changes";
          callback = lib.mkLuaInline ''
            function()
              if vim.o.buftype ~= "nofile" then
                vim.cmd("checktime")
              end
            end
          '';
        }

        # Highlight on yank
        {
          event = [ "TextYankPost" ];
          group = "lazyvim_highlight_yank";
          desc = "Highlight on yank";
          callback = lib.mkLuaInline ''
            function()
              (vim.hl or vim.highlight).on_yank()
            end
          '';
        }

        # resize splits if window got resized
        {
          event = [ "VimResized" ];
          group = "lazyvim_resize_splits";
          desc = "Resize splits when window is resized";
          callback = lib.mkLuaInline ''
            function()
              local current_tab = vim.fn.tabpagenr()
              vim.cmd("tabdo wincmd =")
              vim.cmd("tabnext " .. current_tab)
            end
          '';
        }

        # go to last loc when opening a buffer
        {
          event = [ "BufReadPost" ];
          group = "lazyvim_last_loc";
          desc = "Go to last location when opening buffer";
          callback = lib.mkLuaInline ''
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

        # close some filetypes with <q>
        {
          event = [ "FileType" ];
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
          desc = "Close filetypes with q";
          callback = lib.mkLuaInline ''
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

        # make it easier to close man-files when opened inline
        {
          event = [ "FileType" ];
          pattern = [ "man" ];
          group = "lazyvim_man_unlisted";
          desc = "Make man files unlisted";
          callback = lib.mkLuaInline ''
            function(event)
              vim.bo[event.buf].buflisted = false
            end
          '';
        }

        # wrap and check for spell in text filetypes
        {
          event = [ "FileType" ];
          pattern = [ "text" "plaintex" "typst" "gitcommit" "markdown" ];
          group = "lazyvim_wrap_spell";
          desc = "Wrap and spell check for text filetypes";
          callback = lib.mkLuaInline ''
            function()
              vim.opt_local.wrap = true
              vim.opt_local.spell = true
            end
          '';
        }

        # Fix conceallevel for json files
        {
          event = [ "FileType" ];
          pattern = [ "json" "jsonc" "json5" ];
          group = "lazyvim_json_conceal";
          desc = "Fix conceallevel for JSON files";
          callback = lib.mkLuaInline ''
            function()
              vim.opt_local.conceallevel = 0
            end
          '';
        }

        # Auto create dir when saving a file
        {
          event = [ "BufWritePre" ];
          group = "lazyvim_auto_create_dir";
          desc = "Auto create directory when saving file";
          callback = lib.mkLuaInline ''
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
      # LazyVim-style keymaps
      keymaps = [
        # Better up/down navigation
        {
          key = "j";
          mode = [ "n" "x" ];
          action = "v:count == 0 ? 'gj' : 'j'";
          desc = "Down";
          expr = true;
          silent = true;
        }
        {
          key = "<Down>";
          mode = [ "n" "x" ];
          action = "v:count == 0 ? 'gj' : 'j'";
          desc = "Down";
          expr = true;
          silent = true;
        }
        {
          key = "k";
          mode = [ "n" "x" ];
          action = "v:count == 0 ? 'gk' : 'k'";
          desc = "Up";
          expr = true;
          silent = true;
        }
        {
          key = "<Up>";
          mode = [ "n" "x" ];
          action = "v:count == 0 ? 'gk' : 'k'";
          desc = "Up";
          expr = true;
          silent = true;
        }

        # Window navigation with Ctrl+hjkl
        {
          key = "<C-h>";
          mode = [ "n" ];
          action = "<C-w>h";
          desc = "Go to Left Window";
        }
        {
          key = "<C-j>";
          mode = [ "n" ];
          action = "<C-w>j";
          desc = "Go to Lower Window";
        }
        {
          key = "<C-k>";
          mode = [ "n" ];
          action = "<C-w>k";
          desc = "Go to Upper Window";
        }
        {
          key = "<C-l>";
          mode = [ "n" ];
          action = "<C-w>l";
          desc = "Go to Right Window";
        }

        # Window resizing with Ctrl+arrow keys
        {
          key = "<C-Up>";
          mode = [ "n" ];
          action = "<cmd>resize +2<cr>";
          desc = "Increase Window Height";
        }
        {
          key = "<C-Down>";
          mode = [ "n" ];
          action = "<cmd>resize -2<cr>";
          desc = "Decrease Window Height";
        }
        {
          key = "<C-Left>";
          mode = [ "n" ];
          action = "<cmd>vertical resize -2<cr>";
          desc = "Decrease Window Width";
        }
        {
          key = "<C-Right>";
          mode = [ "n" ];
          action = "<cmd>vertical resize +2<cr>";
          desc = "Increase Window Width";
        }

        # Move lines with Alt+j/k
        {
          key = "<A-j>";
          mode = [ "n" ];
          action = "<cmd>execute 'move .+' . v:count1<cr>==";
          desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = [ "n" ];
          action = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==";
          desc = "Move Up";
        }
        {
          key = "<A-j>";
          mode = [ "i" ];
          action = "<esc><cmd>m .+1<cr>==gi";
          desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = [ "i" ];
          action = "<esc><cmd>m .-2<cr>==gi";
          desc = "Move Up";
        }
        {
          key = "<A-j>";
          mode = [ "v" ];
          action = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv";
          desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = [ "v" ];
          action = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv";
          desc = "Move Up";
        }

        # Buffer navigation
        {
          key = "<S-h>";
          mode = [ "n" ];
          action = "<cmd>bprevious<cr>";
          desc = "Prev Buffer";
        }
        {
          key = "<S-l>";
          mode = [ "n" ];
          action = "<cmd>bnext<cr>";
          desc = "Next Buffer";
        }
        {
          key = "[b";
          mode = [ "n" ];
          action = "<cmd>bprevious<cr>";
          desc = "Prev Buffer";
        }
        {
          key = "]b";
          mode = [ "n" ];
          action = "<cmd>bnext<cr>";
          desc = "Next Buffer";
        }
        {
          key = "<leader>bb";
          mode = [ "n" ];
          action = "<cmd>e #<cr>";
          desc = "Switch to Other Buffer";
        }
        {
          key = "<leader>`";
          mode = [ "n" ];
          action = "<cmd>e #<cr>";
          desc = "Switch to Other Buffer";
        }
        {
          key = "<leader>bd";
          mode = [ "n" ];
          action = "function() Snacks.bufdelete() end";
          desc = "Delete Buffer";
          lua = true;
        }
        {
          key = "<leader>bo";
          mode = [ "n" ];
          action = "function() Snacks.bufdelete.other() end";
          desc = "Delete Other Buffers";
          lua = true;
        }
        {
          key = "<leader>bD";
          mode = [ "n" ];
          action = "<cmd>:bd<cr>";
          desc = "Delete Buffer and Window";
        }

        # Clear search and stop snippet on escape
        {
          key = "<esc>";
          mode = [ "i" "n" "s" ];
          action = "function() vim.cmd('noh') if LazyVim and LazyVim.cmp and LazyVim.cmp.actions then LazyVim.cmp.actions.snippet_stop() end return '<esc>' end";
          desc = "Escape and Clear hlsearch";
          expr = true;
          lua = true;
        }

        # Clear search, diff update and redraw
        {
          key = "<leader>ur";
          mode = [ "n" ];
          action = "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>";
          desc = "Redraw / Clear hlsearch / Diff Update";
        }

        # Better search behavior
        {
          key = "n";
          mode = [ "n" ];
          action = "'Nn'[v:searchforward].'zv'";
          desc = "Next Search Result";
          expr = true;
        }
        {
          key = "n";
          mode = [ "x" ];
          action = "'Nn'[v:searchforward]";
          desc = "Next Search Result";
          expr = true;
        }
        {
          key = "n";
          mode = [ "o" ];
          action = "'Nn'[v:searchforward]";
          desc = "Next Search Result";
          expr = true;
        }
        {
          key = "N";
          mode = [ "n" ];
          action = "'nN'[v:searchforward].'zv'";
          desc = "Prev Search Result";
          expr = true;
        }
        {
          key = "N";
          mode = [ "x" ];
          action = "'nN'[v:searchforward]";
          desc = "Prev Search Result";
          expr = true;
        }
        {
          key = "N";
          mode = [ "o" ];
          action = "'nN'[v:searchforward]";
          desc = "Prev Search Result";
          expr = true;
        }

        # Add undo break-points
        {
          key = ",";
          mode = [ "i" ];
          action = ",<c-g>u";
        }
        {
          key = ".";
          mode = [ "i" ];
          action = ".<c-g>u";
        }
        {
          key = ";";
          mode = [ "i" ];
          action = ";<c-g>u";
        }

        # Save file
        {
          key = "<C-s>";
          mode = [ "i" "x" "n" "s" ];
          action = "<cmd>w<cr><esc>";
          desc = "Save File";
        }

        # Keywordprg
        {
          key = "<leader>K";
          mode = [ "n" ];
          action = "<cmd>norm! K<cr>";
          desc = "Keywordprg";
        }

        # Better indenting
        {
          key = "<";
          mode = [ "v" ];
          action = "<gv";
        }
        {
          key = ">";
          mode = [ "v" ];
          action = ">gv";
        }

        # Commenting
        {
          key = "gco";
          mode = [ "n" ];
          action = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          desc = "Add Comment Below";
        }
        {
          key = "gcO";
          mode = [ "n" ];
          action = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          desc = "Add Comment Above";
        }

        # Lazy
        {
          key = "<leader>l";
          mode = [ "n" ];
          action = "<cmd>Lazy<cr>";
          desc = "Lazy";
        }

        # New file
        {
          key = "<leader>fn";
          mode = [ "n" ];
          action = "<cmd>enew<cr>";
          desc = "New File";
        }

        # Location list
        {
          key = "<leader>xl";
          mode = [ "n" ];
          action = "function() local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen) if not success and err then vim.notify(err, vim.log.levels.ERROR) end end";
          desc = "Location List";
          lua = true;
        }

        # Quickfix list
        {
          key = "<leader>xq";
          mode = [ "n" ];
          action = "function() local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen) if not success and err then vim.notify(err, vim.log.levels.ERROR) end end";
          desc = "Quickfix List";
          lua = true;
        }
        {
          key = "[q";
          mode = [ "n" ];
          action = "vim.cmd.cprev";
          desc = "Previous Quickfix";
          lua = true;
        }
        {
          key = "]q";
          mode = [ "n" ];
          action = "vim.cmd.cnext";
          desc = "Next Quickfix";
          lua = true;
        }

        # Formatting
        {
          key = "<leader>cf";
          mode = [ "n" "v" ];
          action = "function() LazyVim.format({ force = true }) end";
          desc = "Format";
          lua = true;
        }

        # Diagnostics
        {
          key = "<leader>cd";
          mode = [ "n" ];
          action = "vim.diagnostic.open_float";
          desc = "Line Diagnostics";
          lua = true;
        }
        {
          key = "]d";
          mode = [ "n" ];
          action = "function() local go = vim.diagnostic.goto_next go({ severity = nil }) end";
          desc = "Next Diagnostic";
          lua = true;
        }
        {
          key = "[d";
          mode = [ "n" ];
          action = "function() local go = vim.diagnostic.goto_prev go({ severity = nil }) end";
          desc = "Prev Diagnostic";
          lua = true;
        }
        {
          key = "]e";
          mode = [ "n" ];
          action = "function() local go = vim.diagnostic.goto_next go({ severity = vim.diagnostic.severity.ERROR }) end";
          desc = "Next Error";
          lua = true;
        }
        {
          key = "[e";
          mode = [ "n" ];
          action = "function() local go = vim.diagnostic.goto_prev go({ severity = vim.diagnostic.severity.ERROR }) end";
          desc = "Prev Error";
          lua = true;
        }
        {
          key = "]w";
          mode = [ "n" ];
          action = "function() local go = vim.diagnostic.goto_next go({ severity = vim.diagnostic.severity.WARN }) end";
          desc = "Next Warning";
          lua = true;
        }
        {
          key = "[w";
          mode = [ "n" ];
          action = "function() local go = vim.diagnostic.goto_prev go({ severity = vim.diagnostic.severity.WARN }) end";
          desc = "Prev Warning";
          lua = true;
        }

        # Toggle options (using Snacks)
        {
          key = "<leader>uf";
          mode = [ "n" ];
          action = "function() LazyVim.format.snacks_toggle()() end";
          desc = "Toggle Format on Save";
          lua = true;
        }
        {
          key = "<leader>uF";
          mode = [ "n" ];
          action = "function() LazyVim.format.snacks_toggle(true)() end";
          desc = "Toggle Format on Save (Global)";
          lua = true;
        }
        {
          key = "<leader>us";
          mode = [ "n" ];
          action = "function() Snacks.toggle.option('spell', { name = 'Spelling' })() end";
          desc = "Toggle Spelling";
          lua = true;
        }
        {
          key = "<leader>uw";
          mode = [ "n" ];
          action = "function() Snacks.toggle.option('wrap', { name = 'Wrap' })() end";
          desc = "Toggle Wrap";
          lua = true;
        }
        {
          key = "<leader>uL";
          mode = [ "n" ];
          action = "function() Snacks.toggle.option('relativenumber', { name = 'Relative Number' })() end";
          desc = "Toggle Relative Number";
          lua = true;
        }
        {
          key = "<leader>ud";
          mode = [ "n" ];
          action = "function() Snacks.toggle.diagnostics()() end";
          desc = "Toggle Diagnostics";
          lua = true;
        }
        {
          key = "<leader>ul";
          mode = [ "n" ];
          action = "function() Snacks.toggle.line_number()() end";
          desc = "Toggle Line Number";
          lua = true;
        }
        {
          key = "<leader>uc";
          mode = [ "n" ];
          action = "function() Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = 'Conceal Level' })() end";
          desc = "Toggle Conceal Level";
          lua = true;
        }
        {
          key = "<leader>uA";
          mode = [ "n" ];
          action = "function() Snacks.toggle.option('showtabline', { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = 'Tabline' })() end";
          desc = "Toggle Tabline";
          lua = true;
        }
        {
          key = "<leader>uT";
          mode = [ "n" ];
          action = "function() Snacks.toggle.treesitter()() end";
          desc = "Toggle Treesitter";
          lua = true;
        }
        {
          key = "<leader>ub";
          mode = [ "n" ];
          action = "function() Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' })() end";
          desc = "Toggle Dark Background";
          lua = true;
        }
        {
          key = "<leader>uD";
          mode = [ "n" ];
          action = "function() Snacks.toggle.dim()() end";
          desc = "Toggle Dim";
          lua = true;
        }
        {
          key = "<leader>ua";
          mode = [ "n" ];
          action = "function() Snacks.toggle.animate()() end";
          desc = "Toggle Animate";
          lua = true;
        }
        {
          key = "<leader>ug";
          mode = [ "n" ];
          action = "function() Snacks.toggle.indent()() end";
          desc = "Toggle Indent";
          lua = true;
        }
        {
          key = "<leader>uS";
          mode = [ "n" ];
          action = "function() Snacks.toggle.scroll()() end";
          desc = "Toggle Scroll";
          lua = true;
        }
        {
          key = "<leader>dpp";
          mode = [ "n" ];
          action = "function() Snacks.toggle.profiler()() end";
          desc = "Toggle Profiler";
          lua = true;
        }
        {
          key = "<leader>dph";
          mode = [ "n" ];
          action = "function() Snacks.toggle.profiler_highlights()() end";
          desc = "Toggle Profiler Highlights";
          lua = true;
        }
        {
          key = "<leader>uh";
          mode = [ "n" ];
          action = "function() if vim.lsp.inlay_hint then Snacks.toggle.inlay_hints()() end end";
          desc = "Toggle Inlay Hints";
          lua = true;
        }

        # Git operations
        {
          key = "<leader>gg";
          mode = [ "n" ];
          action = "function() if vim.fn.executable('lazygit') == 1 then Snacks.lazygit({ cwd = LazyVim.root.git() }) end end";
          desc = "Lazygit (Root Dir)";
          lua = true;
        }
        {
          key = "<leader>gG";
          mode = [ "n" ];
          action = "function() if vim.fn.executable('lazygit') == 1 then Snacks.lazygit() end end";
          desc = "Lazygit (cwd)";
          lua = true;
        }
        {
          key = "<leader>gf";
          mode = [ "n" ];
          action = "function() if vim.fn.executable('lazygit') == 1 then Snacks.picker.git_log_file() end end";
          desc = "Git Current File History";
          lua = true;
        }
        {
          key = "<leader>gl";
          mode = [ "n" ];
          action = "function() if vim.fn.executable('lazygit') == 1 then Snacks.picker.git_log({ cwd = LazyVim.root.git() }) end end";
          desc = "Git Log";
          lua = true;
        }
        {
          key = "<leader>gL";
          mode = [ "n" ];
          action = "function() if vim.fn.executable('lazygit') == 1 then Snacks.picker.git_log() end end";
          desc = "Git Log (cwd)";
          lua = true;
        }
        {
          key = "<leader>gb";
          mode = [ "n" ];
          action = "function() Snacks.picker.git_log_line() end";
          desc = "Git Blame Line";
          lua = true;
        }
        {
          key = "<leader>gB";
          mode = [ "n" "x" ];
          action = "function() Snacks.gitbrowse() end";
          desc = "Git Browse (open)";
          lua = true;
        }
        {
          key = "<leader>gY";
          mode = [ "n" "x" ];
          action = "function() Snacks.gitbrowse({ open = function(url) vim.fn.setreg('+', url) end, notify = false }) end";
          desc = "Git Browse (copy)";
          lua = true;
        }

        # Quit
        {
          key = "<leader>qq";
          mode = [ "n" ];
          action = "<cmd>qa<cr>";
          desc = "Quit All";
        }

        # Highlights under cursor
        {
          key = "<leader>ui";
          mode = [ "n" ];
          action = "vim.show_pos";
          desc = "Inspect Pos";
          lua = true;
        }
        {
          key = "<leader>uI";
          mode = [ "n" ];
          action = "function() vim.treesitter.inspect_tree() vim.api.nvim_input('I') end";
          desc = "Inspect Tree";
          lua = true;
        }

        # LazyVim Changelog
        {
          key = "<leader>L";
          mode = [ "n" ];
          action = "function() LazyVim.news.changelog() end";
          desc = "LazyVim Changelog";
          lua = true;
        }

        # Floating terminal
        {
          key = "<leader>fT";
          mode = [ "n" ];
          action = "function() Snacks.terminal() end";
          desc = "Terminal (cwd)";
          lua = true;
        }
        {
          key = "<leader>ft";
          mode = [ "n" ];
          action = "function() Snacks.terminal(nil, { cwd = LazyVim.root() }) end";
          desc = "Terminal (Root Dir)";
          lua = true;
        }
        {
          key = "<c-/>";
          mode = [ "n" ];
          action = "function() Snacks.terminal(nil, { cwd = LazyVim.root() }) end";
          desc = "Terminal (Root Dir)";
          lua = true;
        }
        {
          key = "<c-_>";
          mode = [ "n" ];
          action = "function() Snacks.terminal(nil, { cwd = LazyVim.root() }) end";
          desc = "which_key_ignore";
          lua = true;
        }

        # Terminal mappings
        {
          key = "<C-/>";
          mode = [ "t" ];
          action = "<cmd>close<cr>";
          desc = "Hide Terminal";
        }
        {
          key = "<c-_>";
          mode = [ "t" ];
          action = "<cmd>close<cr>";
          desc = "which_key_ignore";
        }

        # Windows
        {
          key = "<leader>-";
          mode = [ "n" ];
          action = "<C-W>s";
          desc = "Split Window Below";
        }
        {
          key = "<leader>|";
          mode = [ "n" ];
          action = "<C-W>v";
          desc = "Split Window Right";
        }
        {
          key = "<leader>wd";
          mode = [ "n" ];
          action = "<C-W>c";
          desc = "Delete Window";
        }
        {
          key = "<leader>wm";
          mode = [ "n" ];
          action = "function() Snacks.toggle.zoom()() end";
          desc = "Toggle Zoom";
          lua = true;
        }
        {
          key = "<leader>uZ";
          mode = [ "n" ];
          action = "function() Snacks.toggle.zoom()() end";
          desc = "Toggle Zoom";
          lua = true;
        }
        {
          key = "<leader>uz";
          mode = [ "n" ];
          action = "function() Snacks.toggle.zen()() end";
          desc = "Toggle Zen";
          lua = true;
        }

        # Tabs
        {
          key = "<leader><tab>l";
          mode = [ "n" ];
          action = "<cmd>tablast<cr>";
          desc = "Last Tab";
        }
        {
          key = "<leader><tab>o";
          mode = [ "n" ];
          action = "<cmd>tabonly<cr>";
          desc = "Close Other Tabs";
        }
        {
          key = "<leader><tab>f";
          mode = [ "n" ];
          action = "<cmd>tabfirst<cr>";
          desc = "First Tab";
        }
        {
          key = "<leader><tab><tab>";
          mode = [ "n" ];
          action = "<cmd>tabnew<cr>";
          desc = "New Tab";
        }
        {
          key = "<leader><tab>]";
          mode = [ "n" ];
          action = "<cmd>tabnext<cr>";
          desc = "Next Tab";
        }
        {
          key = "<leader><tab>d";
          mode = [ "n" ];
          action = "<cmd>tabclose<cr>";
          desc = "Close Tab";
        }
        {
          key = "<leader><tab>[";
          mode = [ "n" ];
          action = "<cmd>tabprevious<cr>";
          desc = "Previous Tab";
        }
      ];

      # Additional which-key registrations for better organization
      binds.whichKey.register = {
        "<leader><tab>" = "tabs";
        "<leader>c" = "code";
        "<leader>d" = "debug";
        "<leader>dp" = "profiler";
        "<leader>f" = "file/find";
        "<leader>g" = "git";
        "<leader>gh" = "hunks";
        "<leader>q" = "quit/session";
        "<leader>s" = "search";
        "<leader>u" = "ui";
        "<leader>x" = "diagnostics/quickfix";
        "[" = "prev";
        "]" = "next";
        "g" = "goto";
        "gs" = "surround";
        "z" = "fold";
        "gx" = "Open with system app";
      };
    };
  };
}
