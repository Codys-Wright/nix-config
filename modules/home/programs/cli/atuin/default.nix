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
  cfg = config.${namespace}.programs.cli.atuin;
in
{
  options.${namespace}.programs.cli.atuin = with types; {
    enable = mkBoolOpt false "Enable atuin shell history manager";
    enableBashIntegration = mkBoolOpt false "Enable bash integration";
    enableZshIntegration = mkBoolOpt true "Enable zsh integration";
    enableFishIntegration = mkBoolOpt false "Enable fish integration";
    autoSync = mkBoolOpt true "Enable automatic sync";
    syncAddress = mkOpt str "https://api.atuin.sh" "Sync server address";
    syncFrequency = mkOpt str "30m" "Sync frequency";
    updateCheck = mkBoolOpt false "Enable update checks";
    filterMode = mkOpt str "global" "Filter mode for history search";
    invert = mkBoolOpt true "Invert search results";
    enterAccept = mkBoolOpt true "Accept on enter";
    showHelp = mkBoolOpt true "Show help text";
    prefersReducedMotion = mkBoolOpt true "Prefer reduced motion";
    style = mkOpt str "compact" "Display style";
    inlineHeight = mkOpt int 10 "Inline height";
    searchMode = mkOpt str "fuzzy" "Search mode";
    filterModeShellUpKeyBinding = mkOpt str "session" "Filter mode shell up key binding";
    historyFilter = mkOpt (listOf str) [
      "^base64decode"
      "^instagram-dl"
      "^mp4concat"
    ] "History filter patterns";
    disableUpArrow = mkBoolOpt true "Disable up arrow functionality";
    keyPath = mkOpt str "" "Path to atuin key file (for sops integration)";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableBashIntegration = cfg.enableBashIntegration;
      enableZshIntegration = cfg.enableZshIntegration;
      enableFishIntegration = cfg.enableFishIntegration;

      settings = {
        auto_sync = cfg.autoSync;
        sync_address = cfg.syncAddress;
        sync_frequency = cfg.syncFrequency;
        update_check = cfg.updateCheck;
        filter_mode = cfg.filterMode;
        invert = cfg.invert;
        enter_accept = cfg.enterAccept;
        show_help = cfg.showHelp;
        prefers_reduced_motion = cfg.prefersReducedMotion;
        style = cfg.style;
        inline_height = cfg.inlineHeight;
        search_mode = cfg.searchMode;
        filter_mode_shell_up_key_binding = cfg.filterModeShellUpKeyBinding;
        history_filter = cfg.historyFilter;
      };

      flags = mkIf cfg.disableUpArrow [ "--disable-up-arrow" ];
    };

    # Sops integration for atuin key
    sops.secrets."keys/atuin" = mkIf (cfg.keyPath != "") {
      path = cfg.keyPath;
      sopsFile = config.sops.secrets."keys/atuin".sopsFile or "${config.sops.secretsDir}/shared.yaml";
    };

    # Zsh integration for down arrow binding (when invert is enabled)
    programs.zsh.initExtra = mkIf (cfg.enableZshIntegration && cfg.invert) ''
      # Bind down key for atuin, specifically because we use invert
      bindkey "$key[Down]"  atuin-up-search
    '';
  };
} 