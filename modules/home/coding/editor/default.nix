{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor;
in
{
  options.${namespace}.coding.editor = with types; {
    enable = mkBoolOpt false "Enable code editors";
  };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      zed-editor
    ];

    # Enable individual editors
    ${namespace}.coding.editor = {
      zed-editor = disabled;
      nvim = enabled;
      code-cursor = enabled;
    };
  };
} 