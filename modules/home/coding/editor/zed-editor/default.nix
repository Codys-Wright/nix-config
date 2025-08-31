{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.zed-editor;
in
{
  options.${namespace}.coding.editor.zed-editor = {
    enable = mkBoolOpt false "Enable Zed editor"; 
  };

   


  config = mkIf cfg.enable {




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
        # Terminal
        {
          context = "Workspace";
          bindings = {
            "ctrl-/" = "workspace::ToggleBottomDock";
          };
        }
        # Window's navigation
        {
          context = "Dock || Terminal || Editor";
          bindings = {
            # Window's motions
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";
          };
        }
        {
          context = "GitPanel";
          bindings = {
            "q" = "git_panel::Close";
          };
        }
        {
          context = "AgentPanel";
          bindings = {
            "ctrl-\\" = "workspace::ToggleRightDock";
            "cmd-k" = "workspace::ToggleRightDock";
          };
        }
        # File panel (netrw)
        {
          context = "ProjectPanel && not_editing";
          bindings = {
            "a" = "project_panel::NewFile";
            "A" = "project_panel::NewDirectory";
            "r" = "project_panel::Rename";
            "d" = "project_panel::Delete";
            "x" = "project_panel::Cut";
            "c" = "project_panel::Copy";
            "p" = "project_panel::Paste";
            # Close project panel as project file panel on the right
            "q" = "workspace::ToggleLeftDock";
            "space e" = "workspace::ToggleLeftDock";
            ":" = "command_palette::Toggle";
            "%" = "project_panel::NewFile";
            "/" = "project_panel::NewSearchInDirectory";
            "enter" = "project_panel::OpenPermanent";
            "escape" = "project_panel::ToggleFocus";
            "h" = "project_panel::CollapseSelectedEntry";
            "j" = "menu::SelectNext";
            "k" = "menu::SelectPrevious";
            "l" = "project_panel::ExpandSelectedEntry";
            "o" = "project_panel::OpenPermanent";
            "shift-d" = "project_panel::Delete";
            "shift-r" = "project_panel::Rename";
            "t" = "project_panel::OpenPermanent";
            "v" = "project_panel::OpenPermanent";
            "shift-g" = "menu::SelectLast";
            "g g" = "menu::SelectFirst";
            "-" = "project_panel::SelectParent";
            "ctrl-6" = "pane::AlternateFile";
          };
        }
        # Empty pane, set of keybindings that are available when there is no active editor
        {
          context = "EmptyPane || SharedScreen";
          bindings = {
            # Open file finder
            "space space" = "file_finder::Toggle";
            # New file
            "space f n" = "workspace::NewFile";
            # Open recent project
            "space f p" = "projects::OpenRecent";
            # Search in all the files
            "space s g" = "workspace::NewSearch";
            # Quit zed
            "space q q" = "zed::Quit";
          };
        }
        {
          context = "Editor && VimControl && !VimWaiting && !menu";
          bindings = {
            # Refactoring
            "space c r " = "editor::Rename";
            # Chat with AI
            "space a a" = "assistant::ToggleFocus";
            "ctrl-\\" = "workspace::ToggleRightDock";
            "cmd-k" = "workspace::ToggleRightDock";
            "space a e" = "assistant::InlineAssist";
            "cmd-l" = "assistant::InlineAssist";
            "space a t" = "workspace::ToggleRightDock";
            # Git
            "space g g" = [
              "task::Spawn"
              {
                task_name = "lazygit";
                reveal_target = "center";
              }
            ];
            "space g h d" = "editor::ExpandAllDiffHunks";
            "space g h D" = "git::Diff";
            "space g h r" = "git::Restore";
            "space g h R" = "git::RestoreFile";
            # Toggle inlay hints
            "space u i" = "editor::ToggleInlayHints";
            # Toggle soft wrap
            "space u w" = "editor::ToggleSoftWrap";
            # Open markdown preview
            "space m p" = "markdown::OpenPreview";
            "space m P" = "markdown::OpenPreviewToTheSide";
            # Open recent project
            "space f p" = "projects::OpenRecent";
            # Search word under cursor in current pane
            "space s w" = "buffer_search::Deploy";
            # Search word under cursor in all panes
            "space s W" = "pane::DeploySearch";
            # Tab things. Almost as good as harpoon.
            "space 1" = ["pane::ActivateItem" 0];
            "space 2" = ["pane::ActivateItem" 1];
            "space 3" = ["pane::ActivateItem" 2];
            "space 4" = ["pane::ActivateItem" 3];
            "space 5" = ["pane::ActivateItem" 4];
            "space 6" = ["pane::ActivateItem" 5];
            "space 7" = ["pane::ActivateItem" 6];
            "space 8" = ["pane::ActivateItem" 7];
            "space 9" = ["pane::ActivateItem" 8];
            "space 0" = "pane::ActivateLastItem";
            "] b" = "pane::ActivateNextItem";
            "[ b" = "pane::ActivatePreviousItem";
            "space ," = "tab_switcher::Toggle";
            # Jump to the previous location
            "space b b" = "pane::AlternateFile";
            # Close buffer
            "space b d" = "pane::CloseActiveItem";
            # Close inactive buffers
            "space b q" = "pane::CloseInactiveItems";
            # New file
            "space b n" = "workspace::NewFile";
            # Search in the current buffer
            "space s b" = "vim::Search";
            # Search in all the files
            "space s g" = "workspace::NewSearch";
            "space f n" = "workspace::NewFile";
            # Search
            "space /" = "workspace::NewSearch";
            # Git
            "space g b" = "git::Blame";
            # LSP & Code actions
            "space c a" = "editor::ToggleCodeActions";
            "space s d" = "diagnostics::Deploy";
            "space s s" = "outline::Toggle";
            # Format
            "space c f" = "editor::Format";
            # File explorer
            "space e" = "workspace::ToggleLeftDock";
            # Telescope
            "space f f" = "file_finder::Toggle";
            "space space" = "file_finder::Toggle";
            # Quit zed
            "space q q" = "zed::Quit";
            # Terminal
            "space t" = "workspace::ToggleBottomDock";
            # Windows management
            "space w s" = "pane::SplitDown";
            "space w v" = "pane::SplitRight";
            "space -" = "pane::SplitDown";
            "space |" = "pane::SplitRight";
            "space w c" = "pane::CloseAllItems";
            "space w d" = "pane::CloseAllItems";
            # Jump to hunks
            "] h" = "editor::GoToHunk";
            "[ h" = "editor::GoToPreviousHunk";
            "] c" = "editor::GoToHunk";
            "[ c" = "editor::GoToPreviousHunk";
            # Jump to diagnostic
            "] d" = "editor::GoToDiagnostic";
            "[ d" = "editor::GoToPreviousDiagnostic";
            "] e" = "editor::GoToDiagnostic";
            "[ e" = "editor::GoToPreviousDiagnostic";
            # Excerpts
            "] q" = "editor::MoveToStartOfNextExcerpt";
            "[ q" = "editor::MoveToStartOfExcerpt";
          };
        }
        {
          context = "Editor && vim_mode == visual && !VimWaiting && !VimObject";
          bindings = {
            # Line's Motions
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
          };
        }
        # Center the cursor on the screen when scrolling and find all references
        {
          context = "VimControl && !menu";
          bindings = {
            "ctrl-d" = ["workspace::SendKeystrokes" "ctrl-d z z"];
            "ctrl-u" = ["workspace::SendKeystrokes" "ctrl-u z z"];
            "n" = ["workspace::SendKeystrokes" "n z z z v"];
            "shift-n" = ["workspace::SendKeystrokes" "shift-n z z z v"];
            "shift-g" = ["workspace::SendKeystrokes" "shift-g z z"];
            "g r" = "editor::FindAllReferences";
          };
        }
        {
          context = "vim_operator == d";
          bindings = {
            "o" = "editor::ExpandAllDiffHunks";
            "r" = "git::Restore";
          };
        }
        {
          context = "vim_mode == normal || vim_mode == visual";
          bindings = {
            "s" = "vim::PushSneak";
            "S" = "vim::PushSneakBackward";
          };
        }
        {
          context = "vim_operator == a || vim_operator == i || vim_operator == cs";
          bindings = {
            "b" = "vim::AnyBrackets";
          };
        }
      ];

      # User settings configuration
      userSettings = lib.mkForce {
        # Edit predictions configuration
        edit_predictions = {
          disabled_globs = [
            "**/.git"
            "**/.svn"
            "**/.hg"
            "**/CVS"
            "**/.DS_Store"
            "**/Thumbs.db"
            "**/.classpath"
            "**/.settings"
            "**/.vscode"
            "**/.idea"
            "**/node_modules"
            "**/.serverless"
            "**/build"
            "**/dist"
            "**/coverage"
            "**/.venv"
            "**/__pycache__"
            "**/.ropeproject"
            "**/.pytest_cache"
            "**/.ruff_cache"
          ];
          mode = "eager";
          copilot = {
            proxy = null;
            proxy_no_verify = null;
          };
          enabled_in_assistant = false;
        };

        # UI and theme settings
        icon_theme = "Material Icon Theme";
        notification_panel = {
          enabled = false;
          button = false;
        };

        # AI Assistant Configuration
        assistant = {
          default_profile = "ask";
          default_model = {
            provider = "zed.dev";
            model = "claude-3-7-sonnet-latest";
          };
          version = "2";
        };

        show_edit_predictions = true;

        # Language-specific configurations
        languages = {
          "Python" = {
            language_servers = ["ruff" "basedpyright" "!pyright"];
            formatter = [
              {
                code_actions = {
                  "source.organizeImports.ruff" = true;
                  "source.fixAll.ruff" = true;
                };
              }
              {
                language_server = {
                  name = "ruff";
                };
              }
            ];
          };
          "Elixir" = {
            language_servers = ["!lexical" "elixir-ls" "!next-ls"];
            format_on_save = {
              external = {
                command = "mix";
                arguments = ["format" "--stdin-filename" "{buffer_path}" "-"];
              };
            };
          };
          "HEEX" = {
            language_servers = ["!lexical" "elixir-ls" "!next-ls"];
            format_on_save = {
              external = {
                command = "mix";
                arguments = ["format" "--stdin-filename" "{buffer_path}" "-"];
              };
            };
          };
          "Rust" = {
            language_servers = ["rust-analyzer"];
            format_on_save = {
              external = {
                command = "rustfmt";
                arguments = ["--edition" "2021"];
              };
            };
          };
          "Nix" = {
            language_servers = ["nix"];
            format_on_save = {
              external = {
                command = "nixpkgs-fmt";
                arguments = [];
              };
            };
          };
          "TypeScript" = {
            language_servers = ["typescript-language-server"];
            format_on_save = {
              external = {
                command = "prettier";
                arguments = ["--parser" "typescript"];
              };
            };
          };
          "JavaScript" = {
            language_servers = ["typescript-language-server"];
            format_on_save = {
              external = {
                command = "prettier";
                arguments = ["--parser" "babel"];
              };
            };
          };
        };

        # LSP Configuration
        lsp = {
          basedpyright = {
            settings = {
              python = {
                pythonPath = "./.venv/bin/python";
              };
              "basedpyright.analysis" = {
                diagnosticMode = "workspace";
                inlayHints = {
                  callArgumentNames = true;
                  functionReturnTypes = true;
                  variableTypes = true;
                  parameterTypes = true;
                };
              };
            };
          };
          gopls = {
            gofumpt = "on";
            initialization_options = {
              gofumpt = "on";
            };
          };
          "yaml-language-server" = {
            settings = {
              yaml = {
                validate = false;
                customTags = [
                  "!And scalar"
                  "!And mapping"
                  "!And sequence"
                  "!If scalar"
                  "!If mapping"
                  "!If sequence"
                  "!Not scalar"
                  "!Not mapping"
                  "!Not sequence"
                  "!Equals scalar"
                  "!Equals mapping"
                  "!Equals sequence"
                  "!Or scalar"
                  "!Or mapping"
                  "!Or sequence"
                  "!FindInMap scalar"
                  "!FindInMap mapping"
                  "!FindInMap sequence"
                  "!Base64 scalar"
                  "!Base64 mapping"
                  "!Base64 sequence"
                  "!Cidr scalar"
                  "!Cidr mapping"
                  "!Cidr sequence"
                  "!Ref scalar"
                  "!Ref mapping"
                  "!Ref sequence"
                  "!Sub scalar"
                  "!Sub mapping"
                  "!Sub sequence"
                  "!GetAtt scalar"
                  "!GetAtt mapping"
                  "!GetAtt sequence"
                  "!GetAZs scalar"
                  "!GetAZs mapping"
                  "!GetAZs sequence"
                  "!ImportValue scalar"
                  "!ImportValue mapping"
                  "!ImportValue sequence"
                  "!Select scalar"
                  "!Select mapping"
                  "!Select sequence"
                  "!Split scalar"
                  "!Split mapping"
                  "!Split sequence"
                  "!Join scalar"
                  "!Join mapping"
                  "!Join sequence"
                  "!Condition scalar"
                  "!Condition mapping"
                  "!Condition sequence"
                ];
                format = {
                  enable = true;
                  singleQuote = true;
                };
                editor = {
                  tabSize = 4;
                };
                schemas = {
                  "https://raw.githubusercontent.com/lalcebo/json-schema/master/serverless/reference.json" = [
                    "/*"
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
              dialyzerEnabled = true;
            };
          };
        };

        # Basic editor settings
        tab_size = 4;
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        vim_mode = true;
        relative_line_numbers = true;

        # Inlay hints and diagnostics
        inlay_hints = {
          enabled = true;
          parameter_names = true;
          type_annotations = true;
          function_return_types = true;
          variable_types = true;
        };

        # UI components
        scrollbar = {
          show = "never";
        };
        tab_bar = {
          show = true;
          show_nav_history_buttons = false;
        };
        tabs = {
          file_icons = true;
          git_status = true;
        };

        # Indentation guides
        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
        };

        # Terminal configuration
        terminal = {
          env = {
            EDITOR = "zed --wait";
          };
          font_size = 16;
          font_family = "BlexMono Nerd Font Mono";
          detect_venv = {
            on = {
              directories = [".venv" "venv"];
              activate_script = "default";
            };
          };
          button = false;
        };

        # Toolbar settings
        toolbar = {
          title = false;
          quick_actions = false;
        };

        # Layout settings
        centered_layout = {
          left_padding = 0.15;
          right_padding = 0.15;
        };

        # File type associations
        file_types = {
          "Dockerfile" = ["Dockerfile" "Dockerfile.*"];
          "JSON" = ["json" "jsonc" "*.code-snippets"];
        };

        # File scanning
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
          "**/.idea"
          "**/node_modules"
          "**/.serverless"
          "**/build"
          "**/dist"
          "**/coverage"
          "**/.venv"
          "**/__pycache__"
          "**/.ropeproject"
          "**/.pytest_cache"
          "**/.ruff_cache"
        ];
        file_scan_inclusions = [".env"];

        # Panel configurations
        project_panel = {
          button = true;
          default_width = 300;
          dock = "left";
          file_icons = true;
          folder_icons = true;
          git_status = true;
          scrollbar = {
            show = "never";
          };
        };
        outline_panel = {
          dock = "left";
          button = true;
        };
        collaboration_panel = {
          dock = "left";
          button = true;
        };
        chat_panel = {
          dock = "right";
        };

        # Font settings
        ui_font_size = 16;
        buffer_font_size = 16;
        buffer_font_family = "BlexMono Nerd Font Mono";
        ui_font_family = "BlexMono Nerd Font Mono";

        # Auto-save and theme
        autosave = "on_focus_change";
        theme = {
          mode = "dark";
          light = "Catppuccin Latte (Blur)";
          dark = "Catppuccin Espresso (Blur) [Heavy]";
        };

        # Search settings
        search = {
          whole_word = false;
          case_sensitive = true;
          include_ignored = false;
          regex = false;
        };

        # Project settings
        projects_online_by_default = false;
        preferred_line_length = 120;

        # Features
        features = {
          edit_prediction_provider = "zed";
        };

        # Formatter settings
        formatter = {
          language_server = {
            name = "biome";
          };
        };

        # Code actions on format
        code_actions_on_format = {
          "source.fixAll.biome" = true;
          "source.organizeImports.biome" = true;
        };

        # Node.js configuration
        node = {
          path = lib.getExe pkgs.nodejs;
          npm_path = lib.getExe' pkgs.nodejs "npm";
        };

        # Environment and tooling
        load_direnv = "shell_hook";
        base_keymap = "VSCode";
      };
    };
  };
} 
