# Code Cursor editor aspect
{
  FTS, ... }:
{
  FTS.code-cursor = {
    description = "Code Cursor AI-powered editor";

    homeManager = { config, pkgs, lib, ... }: {
      home.packages = with pkgs; [
        code-cursor
      ];

      # Set up desktop entry and file associations
      xdg.desktopEntries = lib.mkIf pkgs.stdenv.isLinux {
        code-cursor = {
          name = "Code Cursor";
          comment = "AI-powered code editor";
          exec = "code-cursor %F";
          icon = "code-cursor";
          startupNotify = true;
          categories = [ "Development" "TextEditor" ];
          mimeType = [
            "text/plain"
            "text/x-chdr"
            "text/x-csrc"
            "text/x-c++hdr"
            "text/x-c++src"
            "text/x-java"
            "text/x-python"
            "text/x-script.python"
            "application/x-python-code"
            "text/x-rust"
            "text/x-go"
            "application/json"
            "application/xml"
            "text/html"
            "text/css"
            "text/javascript"
            "application/javascript"
            "text/x-typescript"
            "application/typescript"
            "text/markdown"
            "text/x-yaml"
            "application/x-yaml"
          ];
        };
      };

      # Shell aliases for convenience
      programs.zsh.shellAliases = {
        cursor = "code-cursor";
        cc = "code-cursor";
      };

      # Environment variables
      home.sessionVariables = {
        # Set Code Cursor as an alternative editor
        VISUAL_ALT = "code-cursor";
      };
    };
  };
}
