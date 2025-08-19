{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.selfhost.utility.ollama;
  selfhostCfg = config.${namespace}.services.selfhost;
in
# pkgs_unstable = import inputs.unstable {
#  system = "x86_64-linux";
#  config.allowUnfree = true;
#};
{
  options.${namespace}.services.selfhost.utility.ollama = with types; {
    enable = mkBoolOpt false "Enable Ollama (local language models)";
    
    acceleration = mkOpt str "cuda" "Hardware acceleration type (cuda, rocm, cpu)";
    
    openWebUI = {
      enable = mkBoolOpt true "Enable Open WebUI interface for Ollama";
      url = mkOpt str "ollama.${selfhostCfg.baseDomain}" "URL for Open WebUI";
    };
    
    homepage = {
      name = mkOpt str "Ollama" "Name shown on homepage";
      description = mkOpt str "Local language model server" "Description shown on homepage";
      icon = mkOpt str "ollama.svg" "Icon shown on homepage";
      category = mkOpt str "Utility" "Category on homepage";
    };
  };

  # disabledModules = [
  #   "services/misc/ollama.nix"
  # ];
  # imports = [
  #   "${inputs.unstable}/nixos/modules/services/misc/ollama.nix"
  # ];
  config = mkIf cfg.enable {
    services = {
      ollama = {
        enable = true;
        port = 11434;
        host = "127.0.0.1";
        acceleration = cfg.acceleration;
        # package = pkgs_unstable.ollama;
      };
      
      open-webui = mkIf cfg.openWebUI.enable {
        enable = true;
        port = 3050;
        host = "127.0.0.1";
        environment = {
          OLLAMA_BASE_URL = "http://127.0.0.1:11434";
          WEBUI_NAME = "Ollama";
        };
      };
    };
    
    # Caddy reverse proxy for Open WebUI
    services.caddy.virtualHosts."${cfg.openWebUI.url}" = mkIf (cfg.openWebUI.enable && selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3050
      '';
    };
  };
}
