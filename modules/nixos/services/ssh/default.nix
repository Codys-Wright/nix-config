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
  cfg = config.${namespace}.services.ssh;
in
{
  options.${namespace}.services.ssh = with types; {
    enable = mkBoolOpt false "Enable ssh";
    rootKeys = mkOpt (listOf str) [] "List of SSH public keys allowed for root login";
    allowRootLogin = mkBoolOpt false "Whether to allow root login via SSH";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = if cfg.allowRootLogin then "yes" else "no";
      };
    };
    
    # Add root keys to authorized_keys if root login is enabled and keys are provided
    users.users.root.openssh.authorizedKeys.keys = mkIf (cfg.allowRootLogin && cfg.rootKeys != []) cfg.rootKeys;
    
    environment.systemPackages = [
      pkgs.sshs
    ];
  };
}
