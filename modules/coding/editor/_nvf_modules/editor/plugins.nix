# Editor plugins (todo-comments, mini.files, aerial outline)
# Split from ../editor.nix — returns config.vim settings directly
{ lib, ... }:
{
  # TODO, FIXME, HACK, etc. comments highlighting and navigation
  notes = {
    todo-comments = {
      enable = true;
      # LazyVim-style todo-comments configuration
      setupOpts = { };
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
            max_width = [
              40
              0.2
            ];
            width = null;
            min_width = 10;
            # key-value pairs of window-local options for aerial window (e.g. wrap, number, etc.)
            win_opts = { };
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
