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
      
      # User keymaps configuration
      userKeymaps = [
        {
          context = "Editor";
          bindings = {
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";
          };
        }
        {
          context = "ProjectPanel && not_editing";
          bindings = {
            "o" = "project_panel::NewFile";
          };
        }
        {
          context = "Editor && vim_mode == normal";
          bindings = {
            "space e" = "workspace::ToggleLeftDock";
            "ctrl-/" = "workspace::ToggleBottomDock";
            "space p" = "editor::Format";
            "space space" = "file_finder::Toggle";
            "shift-l" = "pane::ActivateNextItem";
            "shift-h" = "pane::ActivatePreviousItem";
            "space v" = "pane::SplitRight";
            "space w" = "pane::CloseActiveItem";
            "space h" = "workspace::ActivateNextPane";
            "space l" = "workspace::ActivatePreviousPane";
          };
        }
        {
          context = "Editor && vim_mode == insert";
          bindings = {
            "alt-h" = "vim::Left";
            "alt-l" = "vim::Right";
            "alt-j" = "vim::Down";
            "alt-k" = "vim::Up";
          };
        }
        {
          context = "Editor && vim_mode == visual";
          bindings = {
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
          };
        }
        {
          context = "ProjectPanel";
          bindings = {
            "space e" = "workspace::ToggleLeftDock";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl-/" = "workspace::ToggleBottomDock";
          };
        }
        {
          context = "Dock";
          bindings = {
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";
          };
        }
        {
          context = "Workspace";
          bindings = {};
        }
        {
          context = "vim_operator == a || vim_operator == i || vim_operator == cs";
          bindings = {
            "q" = "vim::AnyQuotes";
            "b" = "vim::AnyBrackets";
            "Q" = "vim::MiniQuotes";
            "B" = "vim::MiniBrackets";
          };
        }
      ];

      # User settings configuration
      userSettings = lib.mkForce {
        # Basic settings
        font_size = 14;
        font_family = "JetBrains Mono";
        
        # Editor settings
        tab_size = 2;
        insert_spaces = true;
        word_wrap = true;
        line_numbers = true;
        
        # File settings
        auto_save = true;
        format_on_save = true;
        
        # Terminal settings
        terminal_font_size = 12;
        
        # Vim mode settings
        vim_mode = true;
        
        # Extensions
        extensions = {};
      };
    };
  };
} 