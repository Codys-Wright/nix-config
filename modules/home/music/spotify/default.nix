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
  cfg = config.${namespace}.music.spotify;
in
{
  options.${namespace}.music.spotify = with types; {
    enable = mkBoolOpt false "Enable ncspot a spotify client";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ncspot
      rmpc
    ];
  };
}
