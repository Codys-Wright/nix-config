# Zed editor aspect with comprehensive configuration
{ ... }:
{
  den.aspects.zed = {
    description = "Zed editor with comprehensive configuration and vim keybindings";

    homeManager = { config, pkgs, lib, ... }: {
      programs.zed-editor = {
        enable = true;

        # Extensions to auto-install
        extensions = [
          "nix"
          "toml"
          "elixir"
          "make"
          "rust"
          "typescript"
          "javascript"
          "json"
          "yaml"
          "markdown"
          "python"
          "go"
          "docker"
        ];

        # Extra packages for LSP servers and tools
        extraPackages = with pkgs; [
          nixd
          shellcheck
          nodejs
          rust-analyzer
          typescript
          prettier
          eslint
          docker
          biome
          yaml-language-server
        ];

        # User keymaps configuration
        userKeymaps = [
          {
            context = "Editor && VimControl && !VimWaiting && !menu";
            bindings = {
              "ctrl-/" = "editor::ToggleComments";
            };
          }
          {
            context = "ProjectPanel && not_editing";
            bindings = {
              "ctrl-h" = "workspace::ActivatePreviousPane";
              "ctrl-l" = "workspace::ActivateNextPane";
              "ctrl-k" = "menu::SelectPrev";
              "ctrl-j" = "menu::SelectNext";
            };
          }
          {
            context = "Terminal";
            bindings = {
              "q" = "terminal_panel::ToggleFocus";
            };
          }
          {
            context = "Dock";
            bindings = {
              "ctrl-\\" = "workspace::ToggleLeftDock";
              "cmd-k" = "workspace::ToggleRightDock";
            };
          }

          # VIM mode keybindings
          {
            context = "Editor && vim_mode == normal";
            bindings = {
              "a" = "vim::Append";
              "A" = "vim::AppendToEndOfLine";
              "r" = "vim::ReplaceChar";
              "d" = "vim::Delete";
              "x" = "vim::DeleteChar";
              "c" = "vim::Change";
              "p" = "vim::Paste";

              "q" = "pane::CloseActiveItem";
              "space e" = "project_panel::ToggleFocus";
              ":" = "command_palette::Toggle";
              "%" = "pane::SplitRight";
              "/" = "buffer_search::Deploy";
              "enter" = "editor::Newline";
              "escape" = "editor::Cancel";
              "h" = "vim::Left";
              "j" = "vim::Down";
              "k" = "vim::Up";
              "l" = "vim::Right";
              "o" = "vim::OpenBelow";
              "shift-d" = "vim::DeleteToEndOfLine";
              "shift-r" = "vim::ReplaceMode";
              "t" = "terminal_panel::ToggleFocus";
              "v" = "vim::ToggleVisual";
              "shift-g" = "vim::EndOfDocument";
              "g g" = "vim::StartOfDocument";
              "-" = "project_panel::ToggleFocus";
              "ctrl-6" = "pane::AlternateFile";
            };
          }

          # General editor keybindings
          {
            context = "Editor";
            bindings = {
              "space space" = "file_finder::Toggle";

              "space f n" = "workspace::NewFile";

              "space f p" = "projects::OpenRecent";

              "space s g" = "project_search::ToggleFocus";

              "space q q" = "zed::Quit";
            };
          }

          {
            context = "Workspace";
            bindings = {
              "space c r " = "editor::Restart";

              "space a a" = "assistant::ToggleFocus";
              "ctrl-\\" = "workspace::ToggleLeftDock";
              "cmd-k" = "workspace::ToggleRightDock";
              "space a e" = "assistant::QuoteSelection";
              "cmd-l" = "assistant::InlineAssist";
              "space a t" = "assistant::ToggleFocus";
              "space g g" = {
                "task_name" = "lazygit";
                "reveal_target" = false;
              };
              "space g h d" = "editor::GoToHunk";
              "space g h D" = "editor::GoToPrevHunk";
              "space g h r" = "editor::RevertSelectedHunks";
              "space g h R" = "git::RevertFile";

              "space u i" = "zed::ToggleInlayHints";

              "space u w" = "editor::ToggleSoftWrap";

              "space m p" = "markdown::OpenPreview";
              "space m P" = "markdown::OpenPreviewToTheSide";

              "space f p" = "file_finder::Toggle";

              "space s w" = "pane::DeploySearch";

              "space s W" = "workspace::DeploySearch";

              "space 1" = ["workspace::ActivatePane" 0];
              "space 2" = ["workspace::ActivatePane" 1];
              "space 3" = ["workspace::ActivatePane" 2];
              "space 4" = ["workspace::ActivatePane" 3];
              "space 5" = ["workspace::ActivatePane" 4];
              "space 6" = ["workspace::ActivatePane" 5];
              "space 7" = ["workspace::ActivatePane" 6];
              "space 8" = ["workspace::ActivatePane" 7];
              "space 9" = ["workspace::ActivatePane" 8];
              "space 0" = ["workspace::ActivatePane" 9];
              "] b" = "pane::ActivateNextItem";
              "[ b" = "pane::ActivatePrevItem";
              "space ," = "zed::OpenSettings";

              "space b b" = "tab_switcher::Toggle";

              "space b d" = "pane::CloseActiveItem";

              "space b q" = "pane::CloseAllItems";

              "space b n" = "workspace::NewFile";

              "space s b" = "outline::Toggle";

              "space s g" = "project_search::ToggleFocus";
              "space f n" = "workspace::NewFile";

              "space /" = "buffer_search::Deploy";

              "space g b" = "editor::ToggleGitBlame";

              "space c a" = "editor::ToggleCodeActions";
              "space s d" = "diagnostics::Deploy";
              "space s s" = "outline::Toggle";

              "space c f" = "editor::Format";

              "space e" = "project_panel::ToggleFocus";

              "space f f" = "file_finder::Toggle";
              "space space" = "file_finder::Toggle";

              "space q q" = "zed::Quit";

              "space t" = "terminal_panel::ToggleFocus";

              "space w s" = "pane::SplitDown";
              "space w v" = "pane::SplitRight";
              "space -" = "pane::SplitDown";
              "space |" = "pane::SplitRight";
              "space w c" = "pane::CloseActiveItem";
              "space w d" = "pane::CloseActiveItem";

              "] h" = "editor::GoToHunk";
              "[ h" = "editor::GoToPrevHunk";
              "] c" = "editor::GoToNextDiagnostic";
              "[ c" = "editor::GoToPrevDiagnostic";

              "] d" = "editor::GoToNextDiagnostic";
              "[ d" = "editor::GoToPrevDiagnostic";
              "] e" = "editor::GoToNextDiagnostic";
              "[ e" = "editor::GoToPrevDiagnostic";

              "] q" = "search::SelectNextMatch";
              "[ q" = "search::SelectPrevMatch";
            };
          }

          # Visual mode keybindings
          {
            context = "Editor && vim_mode == visual";
            bindings = {
              "shift-j" = "editor::MoveLineDown";
              "shift-k" = "editor::MoveLineUp";
            };
          }

          # Search mode keybindings
          {
            context = "ProjectSearchBar";
            bindings = {
              "ctrl-d" = "search::NextHistoryQuery";
              "ctrl-u" = "search::PreviousHistoryQuery";
              "n" = "search::SelectNextMatch";
              "shift-n" = "search::SelectPrevMatch";
              "shift-g" = "search::SelectLastMatch";
              "g r" = "search::SelectAllMatches";
            };
          }

          {
            context = "BufferSearchBar";
            bindings = {
              "o" = "search::ActivateSearchMode";
              "r" = "search::ActivateReplaceMode";
            };
          }

          {
            context = "Terminal";
            bindings = {
              "s" = "workspace::NewTerminal";
              "S" = "terminal_panel::ToggleFocus";
            };
          }

          {
            context = "EmptyPane || SharedScreen";
            bindings = {
              "b" = "branch_list::Toggle";
            };
          }
        ];

        # Comprehensive user settings
        userSettings = {
          # AI edit predictions
          edit_predictions = {
            disabled_globs = [
              "**/.env*"
              "**/secrets/**"
              "**/secret/**"
              "**/.secret*"
              "**/password*"
              "**/key*"
              "**/.key*"
              "**/token*"
              "**/.token*"
              "**/credentials*"
              "**/.credentials*"
              "**/auth*"
              "**/.auth*"
              "**/config*"
              "**/.config*"
            ];
            mode = "on";
            copilot = {
              proxy = null;
              proxy_no_verify = false;
            };
            enabled_in_assistant = false;
          };

          # Theme and UI
          icon_theme = "outline";
          notification_panel = {
            enabled = true;
            button = false;
          };

          # Assistant configuration
          assistant = {
            default_profile = null;
            default_model = {
              provider = "copilot_chat";
              model = "gpt-4";
            };
            version = "2";
          };

          show_edit_predictions = true;

          # Language specific configurations
          languages = {
            "Python" = {
              language_servers = ["basedpyright" "ruff"];
              formatter = {
                code_actions = {
                  "source.organizeImports.ruff" = true;
                  "source.fixAll.ruff" = true;
                };

                language_server = {
                  name = "ruff";
                };
              };
            };
            "Elixir" = {
              language_servers = ["elixir-ls"];
              format_on_save = {
                external = {
                  command = "mix";
                  arguments = ["format" "-"];
                };
              };
            };
            "HEEX" = {
              language_servers = ["elixir-ls"];
              format_on_save = {
                external = {
                  command = "mix";
                  arguments = ["format" "-"];
                };
              };
            };
            "Rust" = {
              language_servers = ["rust-analyzer"];
              format_on_save = {
                external = {
                  command = "rustfmt";
                  arguments = ["--emit=stdout"];
                };
              };
            };
            "Nix" = {
              language_servers = ["nix"];
              format_on_save = {
                external = {
                  command = "nixfmt";
                  arguments = [];
                };
              };
            };
            "TypeScript" = {
              language_servers = ["typescript-language-server"];
              format_on_save = {
                external = {
                  command = "prettier";
                  arguments = ["--stdin-filepath" "file.ts"];
                };
              };
            };
            "JavaScript" = {
              language_servers = ["typescript-language-server"];
              format_on_save = {
                external = {
                  command = "prettier";
                  arguments = ["--stdin-filepath" "file.js"];
                };
              };
            };
          };

          # LSP server configurations
          lsp = {
            basedpyright = {
              settings = {
                python = {
                  pythonPath = ".venv/bin/python";
                };
                "basedpyright.analysis" = {
                  diagnosticMode = "workspace";
                  inlayHints = {
                    callArgumentNames = "partial";
                    functionReturnTypes = true;
                    variableTypes = true;
                    parameterTypes = true;
                  };
                };
              };
            };
            gopls = {
              gofumpt = true;
              initialization_options = {
                gofumpt = true;
              };
            };
            "yaml-language-server" = {
              settings = {
                yaml = {
                  validate = true;
                  customTags = [
                    "!And"
                    "!And sequence"
                    "!If"
                    "!If sequence"
                    "!Not"
                    "!Not sequence"
                    "!Equals"
                    "!Equals sequence"
                    "!Or"
                    "!Or sequence"
                    "!FindInMap"
                    "!FindInMap sequence"
                    "!Base64"
                    "!Join"
                    "!Join sequence"
                    "!Cidr"
                    "!Ref"
                    "!Sub"
                    "!Sub sequence"
                    "!GetAtt"
                    "!GetAZs"
                    "!ImportValue"
                    "!ImportValue sequence"
                    "!Select"
                    "!Select sequence"
                    "!Split"
                    "!Split sequence"
                  ];
                  format = {
                    enable = true;
                    singleQuote = false;
                  };
                  editor = {
                    tabSize = 2;
                  };
                  schemas = {
                    "https://raw.githubusercontent.com/lalcebo/json-schema/master/serverless/reference.json" = [
                      "serverless.yml"
                    ];
                  };
                };
              };
            };
            rust-analyzer = {
              binary = {
                path_lookup = true;
              };
            };
            nix = {
              binary = {
                path_lookup = true;
              };
            };
            elixir-ls = {
              binary = {
                path_lookup = true;
              };
              settings = {
                dialyzerEnabled = false;
              };
            };
          };

          # Editor settings
          tab_size = 2;
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          vim_mode = true;
          relative_line_numbers = true;

          # Inlay hints
          inlay_hints = {
            enabled = true;
            parameter_names = true;
            type_annotations = true;
            function_return_types = true;
            variable_types = false;
          };

          # UI elements
          scrollbar = {
            show = "auto";
          };
          tab_bar = {
            show = true;
            show_nav_history_buttons = false;
          };
          tabs = {
            file_icons = true;
            git_status = true;
          };

          # Indent guides
          indent_guides = {
            enabled = true;
            coloring = "indent_aware";
          };

          # Terminal settings
          terminal = {
            env = {
              EDITOR = "zed --wait";
            };
            font_size = 14;
            font_family = "MesloLGS Nerd Font";
            detect_venv = {
              on = {
                directories = [".env" "env" ".venv" "venv"];
                activate_script = "default";
              };
            };
            button = false;
          };

          # Toolbar
          toolbar = {
            title = true;
            quick_actions = false;
          };

          # Layout
          centered_layout = {
            left_padding = 0.15;
            right_padding = 0.15;
          };

          # File handling
          file_types = {
            "Dockerfile" = ["Containerfile"];
            "JSON" = ["json" "jsonc"];
          };

          file_scan_exclusions = [
            "**/.git"
            "**/.svn"
            "**/.hg"
            "**/CVS"
            "**/.DS_Store"
            "**/Thumbs.db"
            "**/.classpath"
            "**/.settings"
            "**/.vscode"
            "**/.next"
            "**/node_modules"
            "**/target"
            "**/.gradle"
            "**/build"
            "**/.idea"
            "**/*.pyc"
            "**/__pycache__"
            "**/.pytest_cache"
            "**/.mypy_cache"
            "**/venv"
            "**/.venv"
            "**/env"
            "**/.env"
          ];
          file_scan_inclusions = [];

          # Panels
          project_panel = {
            button = true;
            default_width = 240;
            dock = "left";
            file_icons = true;
            folder_icons = true;
            git_status = true;
            scrollbar = {
              show = "auto";
            };
          };
          outline_panel = {
            dock = "right";
            button = true;
          };
          collaboration_panel = {
            dock = "left";
            button = true;
          };
          chat_panel = {
            dock = "right";
          };

          # Fonts and appearance
          ui_font_size = 16;
          buffer_font_size = 14;
          buffer_font_family = "MesloLGS Nerd Font";
          ui_font_family = "Zed Plex Sans";

          # Autosave
          autosave = "on_focus_change";
          theme = {
            mode = "system";
            light = "One Light";
            dark = "Catppuccin Mocha";
          };

          # Search settings
          search = {
            whole_word = false;
            case_sensitive = false;
            include_ignored = false;
            regex = false;
          };

          # Project settings
          projects_online_by_default = false;
          preferred_line_length = 100;

          # Features
          features = {
            edit_prediction_provider = "copilot";
          };

          # Formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };

          code_actions_on_format = {
            "source.fixAll.biome" = true;
            "source.organizeImports.biome" = true;
          };

          # Node.js settings
          node = {
            path = "/usr/bin/node";
            npm_path = "/usr/bin/npm";
          };

          # Environment
          load_direnv = "shell_hook";
          base_keymap = "VSCode";
        };
      };

      # Shell aliases for convenience
      programs.zsh.shellAliases = {
        zed = "zed";
        z = "zed";
      };

      # Environment variables
      home.sessionVariables = {
        # Set Zed as an alternative editor
        VISUAL_ALT = "zed";
      };
    };
  };
}
