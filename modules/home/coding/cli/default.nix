{ config, lib, pkgs, namespace, ... }:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.cli;
in
{
  options.${namespace}.coding.cli = with types; {
    enable = mkBoolOpt false "Enable CLI tools";
  };

  config = mkIf cfg.enable {

    ${namespace}.coding.cli = {
      direnv = enabled;
      atuin = enabled;
      btop = enabled;
      eza = enabled;
      fzf = enabled;
      zoxide = enabled;
      yazi = enabled;
      sesh = enabled;
    };


  };
}
