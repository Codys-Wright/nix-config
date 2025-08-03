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
  cfg = config.${namespace}.gaming.steam;
in
{
  options.${namespace}.gaming.steam = with types; {
    enable = mkBoolOpt false "Enable Steam gaming platform";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      steam
      mangohud
    ];
    
    # Enable Steam with gamescope session
    programs.steam = {
      enable = mkForce true;
      gamescopeSession.enable = mkForce true;
    };
    
    # Enable gamemode for better gaming performance
    programs.gamemode.enable = mkForce true;

    # =============================================================================
    # GAMING LAUNCH OPTIONS
    # =============================================================================
    # TO USE GAMEMODE, SET "gamemoderun %command%" in the launch options in steam 
    # or before running the game
    #
    # Available launch options:
    # - gamemoderun %command%     # Optimizes system performance during gaming
    # - mangohud %command%        # Performance monitoring overlay
    # - gamescope %command%       # Better gaming experience with gamescope
    #
    # You can combine them: gamemoderun mangohud %command%
    # =============================================================================
  };
} 