{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.tools.git;
  home = config.${namespace}.config.user;
in
{
  options.${namespace}.coding.tools.git = with types; {
    enable = mkBoolOpt false "Enable git configuration";
    username = mkOpt str home.fullName "Git username";
    useremail = mkOpt str home.email "Git user email";
    delta = mkBoolOpt true "Enable git-delta for better diffs";
    lfs = mkBoolOpt true "Enable Git LFS";
    extraConfig = mkOpt attrs { } "Extra git configuration";
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = cfg.username;
      userEmail = cfg.useremail;
      delta = mkIf cfg.delta {
        enable = true;
        options = {
          line-numbers = true;
          side-by-side = true;
          navigate = true;
        };
      };
      lfs = mkIf cfg.lfs {
        enable = true;
      };
      extraConfig = cfg.extraConfig;
    };
  };
}
