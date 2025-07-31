{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.nautilus;
in
{
  options.${namespace}.programs.nautilus = with types; {
    enable = mkBoolOpt false "Enable nautilus";
  };

  config = mkIf cfg.enable {
    environment = {
      sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
      systemPackages = with pkgs; [
        file-roller
        nautilus
        nautilus-python
      ];

      pathsToLink = [ "/share/nautilus-python/extensions" ];
    };

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };
  };
}
