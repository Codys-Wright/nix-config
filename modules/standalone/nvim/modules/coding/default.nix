{
  config.vim = {
    # Language support
    languages = {
      enableTreesitter = true;
      nix.enable = true;
      rust.enable = true;
      ts.enable = true;
      markdown.enable = true;
      lua = {
        enable = true;
        lsp.lazydev.enable = true;
      };
    };

    # LSP support
    lsp.enable = true;

    # Autocomplete
    autocomplete.nvim-cmp.enable = true;

    # Git integration
    mini.git.enable = true;

    # Fuzzy finding
    telescope.enable = true;
    mini.fuzzy.enable = true;

    # Snippets
    mini.snippets.enable = true;

    # Auto-pairs with enhanced configuration
    mini.pairs = {
      enable = true;
      setupOpts = {
        modes = {
          insert = true;
          command = true;
          terminal = false;
        };
        skip_next = "[[%w%%%'%[%\"%.%`%$]]";
        skip_ts = [ "string" ];
        skip_unbalanced = true;
        markdown = true;
      };
    };

    # Text objects with enhanced configuration
    mini.ai = {
      enable = true;
      setupOpts = {
        n_lines = 500;
        custom_textobjects = {
          o = "require('mini.ai').gen_spec.treesitter({ a = { '@block.outer', '@conditional.outer', '@loop.outer' }, i = { '@block.inner', '@conditional.inner', '@loop.inner' } })";
          f = "require('mini.ai').gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' })";
          c = "require('mini.ai').gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' })";
          t = [ "<([%p%w]-)%f[^<%w][^<>]->.-</%1>" "^<.->().*()</[^/]->$" ];
          d = [ "%f[%d]%d+" ];
          e = [
            [ "%u[%l%d]+%f[^%l%d]" "%f[%S][%l%d]+%f[^%l%d]" "%f[%P][%l%d]+%f[^%l%d]" "^[%l%d]+%f[^%l%d]" ]
            "^().*()$"
          ];
          g = "LazyVim.mini.ai_buffer";
          u = "require('mini.ai').gen_spec.function_call()";
          U = "require('mini.ai').gen_spec.function_call({ name_pattern = '[%w_]' })";
        };
      };
    };
  };
} 