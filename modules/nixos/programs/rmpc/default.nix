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
  cfg = config.${namespace}.programs.rmpc;
in
{
  options.${namespace}.programs.rmpc = with types; {
    enable = mkBoolOpt false "Enable rmpc";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rmpc
    ];
    services.mpd = {
      enable = true;
      musicDirectory = "http://apollo:6600";
      extraConfig = ''
        audio_output {
          type "pipewire"
          name "My PipWire Output"
        }
      '';
      user = "userRunningPipewire";
    };
    systemd.services.mpd.environment = {
      XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.userRunningPipeWire.uid}"; # User-id must match above user. MPD will look inside this directory for the PipeWire socket.
    };

  };
}
