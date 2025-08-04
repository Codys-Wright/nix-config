{ config, lib, pkgs, namespace, inputs, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.editor.nvim.presets.default;
in
{
  options.${namespace}.coding.editor.nvim.presets.default = with types; {
    enable = mkBoolOpt false "Enable default nvim preset";
  };

  config = mkIf cfg.enable {
    # Enable all modules for the default preset
    ${namespace}.coding.editor.nvim.modules = {
      ui.enable = true;
      coding.enable = true;
      editor.enable = true;
      formatting.enable = true;
      linting.enable = true;
      util.enable = true;
    };
  };
}
