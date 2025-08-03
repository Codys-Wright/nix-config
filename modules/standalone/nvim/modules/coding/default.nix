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
      # Additional language support (only languages that exist in nvf)
      assembly.enable = true;
      bash.enable = true;
      clang.enable = true;
      css.enable = true;
      go.enable = true;
      html.enable = true;
      java.enable = true;
      kotlin.enable = true;
      php.enable = true;
      python.enable = true;
      ruby.enable = true;
      scala.enable = true;
      sql.enable = true;
      yaml.enable = true;
    };

    # LSP support
    lsp.enable = true;

    # Treesitter configuration
    treesitter = {
      enable = true;
      highlight.enable = true;
      indent.enable = true;
      incrementalSelection.enable = true;
      mappings = {
        incrementalSelection = {
          init = "<C-space>";
          incrementByNode = "<C-space>";
          incrementByScope = null;
          decrementByNode = "<bs>";
        };
      };
    };

    # Treesitter textobjects
    treesitter.textobjects = {
      enable = true;
      setupOpts = {
        select = {
          enable = true;
          lookahead = true;
          keymaps = {
            af = "@function.outer";
            "if" = "@function.inner";
            ac = "@class.outer";
            ic = "@class.inner";
            aa = "@parameter.outer";
            ia = "@parameter.inner";
            ao = "@block.outer";
            io = "@block.inner";
            as = "@statement.outer";
            is = "@statement.inner";
            ad = "@conditional.outer";
            id = "@conditional.inner";
            al = "@loop.outer";
            il = "@loop.inner";
            at = "@comment.outer";
            it = "@comment.inner";
          };
        };
        move = {
          enable = true;
          set_jumps = true;
          goto_next_start = {
            "]f" = "@function.outer";
            "]c" = "@class.outer";
            "]a" = "@parameter.inner";
            "]o" = "@block.outer";
            "]s" = "@statement.outer";
            "]d" = "@conditional.outer";
            "]l" = "@loop.outer";
          };
          goto_next_end = {
            "]F" = "@function.outer";
            "]C" = "@class.outer";
            "]A" = "@parameter.outer";
            "]O" = "@block.outer";
            "]S" = "@statement.outer";
            "]D" = "@conditional.outer";
            "]L" = "@loop.outer";
          };
          goto_previous_start = {
            "[f" = "@function.outer";
            "[c" = "@class.outer";
            "[a" = "@parameter.inner";
            "[o" = "@block.outer";
            "[s" = "@statement.outer";
            "[d" = "@conditional.outer";
            "[l" = "@loop.outer";
          };
          goto_previous_end = {
            "[F" = "@function.outer";
            "[C" = "@class.outer";
            "[A" = "@parameter.outer";
            "[O" = "@block.outer";
            "[S" = "@statement.outer";
            "[D" = "@conditional.outer";
            "[L" = "@loop.outer";
          };
        };
        swap = {
          enable = true;
          swap_next = {
            "@parameter.inner" = "@parameter.inner";
            "@function.outer" = "@function.outer";
            "@class.outer" = "@class.outer";
          };
          swap_previous = {
            "@parameter.inner" = "@parameter.inner";
            "@function.outer" = "@function.outer";
            "@class.outer" = "@class.outer";
          };
        };
        lsp_interop = {
          enable = true;
          border = "none";
          peek_definition_code = {
            "@function.outer" = "@function.outer";
            "@class.outer" = "@class.outer";
          };
        };
      };
    };

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