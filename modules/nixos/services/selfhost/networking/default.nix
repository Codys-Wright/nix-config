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
  cfg = config.${namespace}.services.selfhost.networking;
in
{
  options.${namespace}.services.selfhost.networking = with types; {
    enable = mkBoolOpt false "Enable networking services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.networking = {
      tailscale.enable = mkDefault true;
      rustdesk-server.enable = mkDefault true;
      syncthing.enable = mkDefault true;
      wireguard-netns.enable = mkDefault true;
      cloudflare-tunnel.enable = mkDefault false;  # Manual enable due to token requirement
    };
  };
} 