{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim;
in
{
  # Import preset system
  imports = [ ./presets ];

  options.${namespace}.coding.editor.nvim = with types; {
    enable = mkBoolOpt false "Enable Neovim editor";
  };

  config = mkIf cfg.enable {
    # Preset system handles all configuration
    # Each preset defines its own complete setup
  };
} 