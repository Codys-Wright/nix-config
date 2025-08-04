{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.modules.snacks;
in
{
  options.${namespace}.coding.editor.nvim.modules.snacks = with types; {
    enable = mkBoolOpt false "Enable nvim snacks picker module";
  };

  config = mkIf cfg.enable {
    # Add required packages for snacks.nvim picker
    home.packages = with pkgs; [
      # ImageMagick for image conversion
      imagemagick
      # Ghostscript for PDF processing
      ghostscript
      # Tectonic for LaTeX processing
      tectonic
      # Mermaid CLI for diagrams
      mermaid-cli
      # SQLite for database support
      sqlite
    ];

    # Configure nvf snacks settings
    programs.nvf.settings.vim = {
      # Enable lazy loading
      lazy.enable = true;

      # Snacks-nvim as lazy plugin - picker only
      utility.snacks-nvim = {
        enable = true;
       
        setupOpts = {
          picker = { enabled = true; };
        };
      };

      # Snacks picker keybindings
      keymaps = [
        # Smart picker test
        {
          key = "<leader><space>";
          mode = [ "n" ];
          action = "function() Snacks.picker.smart() end";
          desc = "Smart Find Files";
          lua = true;
        }
      ];
    };
  };
} 