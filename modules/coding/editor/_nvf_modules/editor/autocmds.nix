# LazyVim-style autocommand groups and autocommands
# Split from ../editor.nix — returns config.vim settings directly
{ lib, ... }:
{
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
      event = [
        "FocusGained"
        "TermClose"
        "TermLeave"
      ];
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
      event = [ "TextYankPost" ];
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
      event = [ "VimResized" ];
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
      event = [ "BufReadPost" ];
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
      event = [ "FileType" ];
      pattern = [ "man" ];
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
      event = [ "FileType" ];
      pattern = [
        "text"
        "plaintex"
        "typst"
        "gitcommit"
        "markdown"
      ];
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
      event = [ "FileType" ];
      pattern = [
        "json"
        "jsonc"
        "json5"
      ];
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
      event = [ "BufWritePre" ];
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
