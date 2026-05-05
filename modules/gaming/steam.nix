# Steam gaming platform aspect
{
  fleet,
  ...
}:
{
  fleet.gaming._.steam = {
    description = "Steam gaming platform with performance optimizations";

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        steamPackage =
          (pkgs.steam.override {
            extraPreBwrapCmds = ''
              if [ -r "$HOME/.steam/steam.pid" ]; then
                steam_pid="$(cat "$HOME/.steam/steam.pid" 2>/dev/null || true)"
                if [ -n "$steam_pid" ] && ! kill -0 "$steam_pid" 2>/dev/null; then
                  rm -f "$HOME/.steam/steam.pid" "$HOME/.steam/steam.pipe" "$HOME/.steam/starting" "$HOME/.local/share/Steam/.crash"
                fi
              fi
            '';
          }).overrideAttrs
            (old: {
              buildCommand = (old.buildCommand or "") + ''
                share_target="$(readlink "$out/share")"
                rm "$out/share"
                cp -R "$share_target" "$out/share"
                chmod -R u+w "$out/share"

                cat > "$out/bin/steam-niri-launch" <<'EOF'
                #!${pkgs.bash}/bin/bash
                set -euo pipefail

                args=()
                for arg in "$@"; do
                  case "$arg" in
                    %U|%u|%F|%f) ;;
                    *) args+=("$arg") ;;
                  esac
                done

                export PULSE_SINK="''${PULSE_SINK:-games}"

                if [ "''${#args[@]}" -eq 0 ] && [ -n "''${NIRI_SOCKET:-}" ]; then
                  steam_window="$(${lib.getExe pkgs.niri} msg -j windows 2>/dev/null | ${lib.getExe pkgs.jq} -r 'map(select((.app_id // "") == "steam")) | first | .id // empty' 2>/dev/null || true)"
                  if [ -n "$steam_window" ]; then
                    ${lib.getExe pkgs.niri} msg action focus-window --id "$steam_window" >/dev/null 2>&1 && exit 0
                  fi
                fi

                exec "@steam@" "''${args[@]}"
                EOF
                substituteInPlace "$out/bin/steam-niri-launch" \
                  --replace-fail "@steam@" "$out/bin/steam"
                chmod +x "$out/bin/steam-niri-launch"

                substituteInPlace "$out/share/applications/steam.desktop" \
                  --replace-fail "Exec=steam %U" "Exec=$out/bin/steam-niri-launch %U" \
                  --replace-quiet "Exec=steam steam://" "Exec=$out/bin/steam-niri-launch steam://"
              '';
            });
      in
      {
        # NOTE: do NOT add `pkgs.steam` here. `programs.steam.enable = true`
        # installs a correctly-wrapped Steam (honoring extraCompatPackages,
        # extraPackages, FHS env, etc.) into the system path. Adding raw
        # `pkgs.steam` on top creates a second unwrapped Steam that wins in
        # PATH, and GE-Proton / extraPackages silently disappear.
        environment.systemPackages = with pkgs; [
          alsa-plugins
          pkgsi686Linux.alsa-plugins
          mangohud
          # steam-tui   # temporarily disabled - Steam CDN rate limiting
          # steamcmd    # temporarily disabled - Steam CDN rate limiting
        ];

        # Enable Steam without forcing a gamescope session. Gamescope stays
        # installed below for per-game launch options when desired.
        programs.steam = {
          package = steamPackage;
          enable = lib.mkForce true;
          gamescopeSession.enable = lib.mkForce false;
          remotePlay.openFirewall = lib.mkDefault true;
          dedicatedServer.openFirewall = lib.mkDefault true;
          localNetworkGameTransfers.openFirewall = lib.mkDefault true;

          # PulseAudio client libs for Proton audio output
          extraPackages = with pkgs; [
            alsa-plugins
            pkgsi686Linux.alsa-plugins
            libpulseaudio
          ];

          # System-wide GE-Proton — available to every user's Steam without
          # per-user protonup installs.
          extraCompatPackages = with pkgs; [
            proton-ge-bin
          ];
        };

        # Enable gamemode for better gaming performance
        programs.gamemode.enable = lib.mkForce true;

        programs.gamescope = {
          enable = lib.mkForce true;
          capSysNice = lib.mkDefault true;
        };

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
