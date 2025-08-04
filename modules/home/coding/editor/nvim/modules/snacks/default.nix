{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.nvim.plugins.snacks;
in
{
  options.programs.nvim.plugins.snacks = {
    enable = mkEnableOption "snacks.nvim";
  };

  config = mkIf cfg.enable {
    programs.nvim = {
      plugins = {
        snacks = {
          enable = true; # Enable by default when module is imported
          priority = 1000;
          lazy = false;
          setupOpts = {
            bigfile = { enabled = true; };
            dashboard = { enabled = true; };
            explorer = { enabled = true; };
            indent = { enabled = true; };
            input = { enabled = true; };
            notifier = {
              enabled = true;
              timeout = 3000;
            };
            picker = { enabled = true; };
            quickfile = { enabled = true; };
            scope = { enabled = true; };
            scroll = { enabled = true; };
            statuscolumn = { enabled = true; };
            words = { enabled = true; };
            styles = {
              notification = {
                # wo = { wrap = true } -- Wrap notifications
              };
            };
          };
        };
      };


    };
  };
} 