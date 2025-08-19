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
  cfg = config.${namespace}.services.selfhost.ollama;
in
# pkgs_unstable = import inputs.unstable {
#  system = "x86_64-linux";
#  config.allowUnfree = true;
#};
{
  options.${namespace}.services.selfhost.ollama = with types; {
    enable = mkBoolOpt false "Enable ollama";
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
        host = "0.0.0.0";
        acceleration = "cuda";
        # package = pkgs_unstable.ollama;
      };
      #nextjs-ollama-llm-ui = {
      #  enable = true;
      #  ollamaUrl = "http://127.0.0.1:11434";
      #  hostname = "0.0.0.0";
      #  port = 3050;
      #};
      open-webui = {
        enable = true;
        port = 3050;
        host = "0.0.0.0";
      };
    };
  };
}
