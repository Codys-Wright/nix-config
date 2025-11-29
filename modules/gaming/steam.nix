# Steam gaming platform aspect
{
  FTS, ... }:
{
  FTS.steam = {
    description = "Steam gaming platform with performance optimizations";

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        steam
        mangohud
        steam-tui
        steamcmd
      ];

      # Enable Steam with gamescope session
      programs.steam = {
        enable = lib.mkForce true;
        gamescopeSession.enable = lib.mkForce true;
        remotePlay.openFirewall = lib.mkDefault true;
        dedicatedServer.openFirewall = lib.mkDefault true;
        localNetworkGameTransfers.openFirewall = lib.mkDefault true;
      };

      # Enable gamemode for better gaming performance
      programs.gamemode.enable = lib.mkForce true;

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
  };
}
