# Neovim editor aspect with nvf configuration
{
  FTS, ... }:
{
  FTS.neovim = {
    description = "Neovim editor with comprehensive configuration using nvf";

    homeManager = { config, pkgs, lib, inputs, ... }: {
      imports = [ inputs.nvf.homeManagerModules.default ];

      programs.nvf = {
        enable = true;
        enableManpages = true;

        settings = {
          vim = {
            viAlias = false;
            vimAlias = true;

            # Enable which-key for keybinding help
            binds.whichKey.enable = true;
            binds.whichKey.setupOpts = {
              preset = "helix";
              notify = true;
              replace = {
                "<cr>" = "RETURN";
                "<leader>" = "SPACE";
                "<space>" = "SPACE";
                "<tab>" = "TAB";
              };
              win.border = "rounded";
            };
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

            # Enable telescope for fuzzy finding
            telescope.enable = true;

            # Enable flash-nvim for enhanced navigation
            utility.motion.flash-nvim.enable = true;
            utility.motion.flash-nvim.mappings = {
              jump = "s";
              remote = "r";
              toggle = "<c-s>";
              treesitter = "S";
              treesitter_search = "R";
            };

            # Diagnostics viewer with trouble.nvim
            lsp.trouble = {
              enable = true;
              mappings = {
                workspaceDiagnostics = "<leader>xx";
                documentDiagnostics = "<leader>xX";
                symbols = "<leader>cs";
                lspReferences = "<leader>cS";
                locList = "<leader>xL";
                quickfix = "<leader>xQ";
              };
              setupOpts = {
                modes = {
                  lsp = {
                    win = { position = "right"; };
                  };
                };
              };
            };

            # Todo comments highlighting and search
            notes.todo-comments = {
              enable = true;
              mappings = {
                telescope = "<leader>st";
                trouble = "<leader>xt";
                quickFix = "<leader>tdq";
              };
              setupOpts = {
                search.command = "rg";
                search.args = [
                  "--color=never"
                  "--no-heading"
                  "--with-filename"
                  "--line-number"
                  "--column"
                ];
                search.pattern = "\\b(KEYWORDS)(\\([^\\)]*\\))?:";
                highlight.pattern = ".*<(KEYWORDS)(\\([^\\)]*\\))?:";
              };
            };

            # Treesitter for syntax highlighting
            treesitter.enable = true;

            # Git integration with gitsigns
            git.gitsigns = {
              enable = true;
              mappings = {
                nextHunk = "]h";
                previousHunk = "[h";
                stageHunk = "<leader>ghs";
                resetHunk = "<leader>ghr";
                stageBuffer = "<leader>ghS";
                undoStageHunk = "<leader>ghu";
                resetBuffer = "<leader>ghR";
                previewHunk = "<leader>ghp";
                blameLine = "<leader>ghb";
                diffThis = "<leader>ghd";
                diffProject = "<leader>ghD";
              };
              setupOpts = {
                signs = {
                  add = { text = "▎"; };
                  change = { text = "▎"; };
                  delete = { text = ""; };
                  topdelete = { text = ""; };
                  changedelete = { text = "▎"; };
                  untracked = { text = "▎"; };
                };
                signs_staged = {
                  add = { text = "▎"; };
                  change = { text = "▎"; };
                  delete = { text = ""; };
                  topdelete = { text = ""; };
                  changedelete = { text = "▎"; };
                };
              };
            };

            # LSP Configuration
            lsp = {
              enable = true;
              formatOnSave = true;
              lspkind.enable = true;
              lightbulb.enable = true;
              lsplines.enable = true;
              nvim-docs-view.enable = true;
            };

            # Language support
            languages = {
              enableLSP = true;
              enableTreesitter = true;
              enableFormat = true;
              enableExtraDiagnostics = true;

              # Language-specific configurations
              nix.enable = true;
              rust.enable = true;
              typescript.enable = true;
              python.enable = true;
              go.enable = true;
              lua.enable = true;
              markdown.enable = true;
              html.enable = true;
              css.enable = true;
              json.enable = true;
              yaml.enable = true;
              bash.enable = true;
            };

            # Completion with nvim-cmp
            autocomplete = {
              enable = true;
              type = "nvim-cmp";
              mappings = {
                complete = "<C-Space>";
                confirm = "<CR>";
                next = "<Tab>";
                previous = "<S-Tab>";
                close = "<C-e>";
                scrollDocsUp = "<C-d>";
                scrollDocsDown = "<C-f>";
              };
            };

            # File explorer
            filetree = {
              nvimTree = {
                enable = true;
                mappings = {
                  toggle = "<leader>e";
                  focus = "<leader>o";
                };
                setupOpts = {
                  disable_netrw = true;
                  hijack_netrw = true;
                  view = {
                    width = 30;
                    side = "left";
                  };
                  renderer = {
                    group_empty = true;
                    highlight_git = true;
                    icons = {
                      show = {
                        file = true;
                        folder = true;
                        folder_arrow = true;
                        git = true;
                      };
                    };
                  };
                };
              };
            };

            # Status line
            statusline = {
              lualine = {
                enable = true;
                theme = "catppuccin";
              };
            };

            # Tab line
            tabline = {
              nvimBufferline = {
                enable = true;
              };
            };

            # Terminal integration
            terminal = {
              toggleterm = {
                enable = true;
                mappings = {
                  open = "<leader>t";
                };
                setupOpts = {
                  direction = "horizontal";
                  size = 15;
                };
              };
            };

            # Session management
            session = {
              nvim-session-manager.enable = true;
            };

            # UI enhancements
            ui = {
              noice.enable = true;
              smartcolumn.enable = true;
              illuminate.enable = true;
              indentBlankline.enable = true;
              borders.enable = true;
            };

            # Additional utility plugins
            utility = {
              surround.enable = true;
              diffview-nvim.enable = true;
              icon-picker.enable = true;
              codeshot.enable = true;
            };

            # Theme
            theme = {
              enable = true;
              name = "catppuccin";
              style = "mocha";
            };

            # Search and replace
            visuals = {
              enable = true;
              nvimWebDevicons.enable = true;
              scrollBar.enable = true;
              smoothScroll.enable = true;
              cellularAutomaton.enable = true;
            };

            # Key mappings
            maps = {
              normal = {
                # Better window navigation
                "<C-h>" = { action = "<C-w>h"; desc = "Move to left window"; };
                "<C-j>" = { action = "<C-w>j"; desc = "Move to bottom window"; };
                "<C-k>" = { action = "<C-w>k"; desc = "Move to top window"; };
                "<C-l>" = { action = "<C-w>l"; desc = "Move to right window"; };

                # Buffer navigation
                "<S-h>" = { action = ":bprevious<CR>"; desc = "Previous buffer"; };
                "<S-l>" = { action = ":bnext<CR>"; desc = "Next buffer"; };
                "<leader>bd" = { action = ":bdelete<CR>"; desc = "Delete buffer"; };

                # Save and quit
                "<leader>w" = { action = ":w<CR>"; desc = "Save file"; };
                "<leader>q" = { action = ":q<CR>"; desc = "Quit"; };
                "<leader>Q" = { action = ":qa<CR>"; desc = "Quit all"; };

                # Clear search highlighting
                "<leader>h" = { action = ":nohlsearch<CR>"; desc = "Clear search highlight"; };

                # Better indenting
                "<" = { action = "<gv"; desc = "Indent left"; };
                ">" = { action = ">gv"; desc = "Indent right"; };
              };

              visual = {
                # Stay in indent mode
                "<" = { action = "<gv"; desc = "Indent left"; };
                ">" = { action = ">gv"; desc = "Indent right"; };

                # Move text up and down
                "J" = { action = ":m '>+1<CR>gv=gv"; desc = "Move text down"; };
                "K" = { action = ":m '<-2<CR>gv=gv"; desc = "Move text up"; };
              };

              insert = {
                # Better escape
                "jk" = { action = "<ESC>"; desc = "Escape"; };
                "kj" = { action = "<ESC>"; desc = "Escape"; };
              };
            };
          };
        };
      };

      # Set environment variables
      home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      # Additional packages that complement neovim
      home.packages = with pkgs; [
        # Language servers and tools
        ripgrep
        fd
        tree-sitter

        # Clipboard support
        wl-clipboard
        xclip

        # Additional development tools
        git
      ];
    };
  };
}
