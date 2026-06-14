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

        # Pinned proton-cachyos compat tool. Best-reported Proton for Forza
        # Horizon 6 and other recent DX12 titles on NVIDIA: stock Proton/GE hit
        # the FHC00 video-card crash + GDK launcher bounce, and *latest* cachyos
        # is currently reported broken — so we pin a known-good `-slr` build.
        # The `.tar.xz` release is already a complete Steam compat tool (ships
        # its own compatibilitytool.vdf with install_path ".") and runs inside
        # pressure-vessel, so no patchelf/fixup is needed.
        #
        # To update: bump pcVersion, then regenerate pcHash from the release's
        # matching `*-${pcVariant}.sha512sum`:
        #   nix hash convert --hash-algo sha512 --to sri <hex-from-sha512sum-file>
        proton-cachyos =
          let
            pcVersion = "11.0-20260601-slr";
            pcVariant = "x86_64_v3"; # AVX2 baseline; THEBATTLESHIP's CPU supports it
          in
          pkgs.stdenvNoCC.mkDerivation {
            pname = "proton-cachyos";
            version = pcVersion;

            src = pkgs.fetchurl {
              url = "https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-${pcVersion}/proton-cachyos-${pcVersion}-${pcVariant}.tar.xz";
              hash = "sha512-eODAes2XGBmjgAAdefJJJ00aUbsx/NGqV9y6bRW2hdhhpur9aDca0ltrFehr3ljr3P/RHSdXvT+2Q4694Ho0dQ==";
            };

            # Prebuilt Windows/Proton payload — never patchelf or strip it; it
            # executes inside Steam's pressure-vessel runtime, not the host.
            setSourceRoot = "sourceRoot=.";
            dontConfigure = true;
            dontBuild = true;
            dontStrip = true;
            dontPatchELF = true;
            dontFixup = true;

            installPhase = ''
              runHook preInstall
              mkdir -p "$out"
              toolroot="$(dirname "$(find . -name compatibilitytool.vdf -print -quit)")"
              if [ -z "$toolroot" ]; then
                echo "proton-cachyos: compatibilitytool.vdf not found in archive" >&2
                exit 1
              fi
              cp -a "$toolroot"/. "$out"/
              runHook postInstall
            '';

            meta = {
              description = "Pinned proton-cachyos Steam compatibility tool (${pcVersion})";
              platforms = [ "x86_64-linux" ];
            };
          };

        # Launch Steam inside a nested gamescope micro-compositor. Steam and
        # every game it launches render into this ONE gamescope window, which
        # behaves like any other niri window — move it to any monitor, resize it,
        # float/tile it. Defaults to a resizable 1080p Big Picture window; flags
        # let you fullscreen, pick an output, upscale, etc.
        #
        # IMPORTANT: this invokes the UNWRAPPED gamescope binary, not the
        # capSysNice setcap wrapper at /run/wrappers/bin/gamescope. That wrapper
        # leaks an ambient cap_sys_nice into children, and Steam's bubblewrap
        # sandbox aborts on unexpected capabilities ("bwrap: Unexpected
        # capabilities but not setuid") — killing the nested Steam instantly.
        # Dropping the wrapper costs only gamescope's realtime scheduling
        # priority, which is negligible for a windowed desktop session.
        # `steam` stays bare so the FHS-wrapped Steam on PATH is used.
        steam-gamescope = pkgs.writeShellScriptBin "steam-gamescope" ''
          set -euo pipefail

          # Usage:  steam-gamescope [extra gamescope args...]
          #   steam-gamescope                          # fullscreen the main (widest) monitor — your 5120x1440
          #   GS_OUTPUT=DP-3 steam-gamescope           # fullscreen a specific monitor instead
          #   GS_WINDOWED=1 steam-gamescope            # windowed/resizable on the main monitor
          #   GS_OUTPUT=none steam-gamescope           # let niri place a plain 1080p window
          #   GS_W=5120 GS_H=1440 steam-gamescope      # force an explicit size
          #   steam-gamescope -w 3840 -h 1080 -F fsr   # render lower on the main monitor, upscale
          #   GS_DESKTOP=1 steam-gamescope             # desktop Steam UI instead of Big Picture
          #   GS_MANGO=1 steam-gamescope               # mangohud overlay (--mangoapp)
          #
          # NOTE: one Steam instance per user. Fully quit your desktop Steam
          # (Steam > Exit) first, otherwise this just focuses the running one and
          # gamescope exits immediately with nothing to host.

          W="''${GS_W:-}"
          H="''${GS_H:-}"
          prefer=()
          fs=()

          # Pick the target monitor. Default = the widest connected output (the
          # 5120x1440 ultrawide, which holds the niri gaming workspace). Override
          # with GS_OUTPUT=<connector>, or GS_OUTPUT=none to leave placement to
          # niri. `niri msg outputs` lists connectors.
          output="''${GS_OUTPUT:-}"
          if [ -z "$output" ] && command -v niri >/dev/null && command -v jq >/dev/null; then
            output="$(niri msg -j outputs 2>/dev/null \
              | jq -r 'to_entries | max_by(.value.logical.width * .value.logical.height) | .key' 2>/dev/null || true)"
          fi

          # Fullscreen the target (unless GS_WINDOWED=1) and, when GS_W/GS_H
          # aren't given, auto-size to that output's logical resolution from niri
          # — which already accounts for rotation and scale (DP-4 -> 5120x1440,
          # a portrait panel -> 1440x2560).
          if [ -n "$output" ] && [ "$output" != "none" ]; then
            prefer=(--prefer-output "$output")
            [ "''${GS_WINDOWED:-0}" = 1 ] || fs=(-f)
            if { [ -z "$W" ] || [ -z "$H" ]; } && command -v niri >/dev/null && command -v jq >/dev/null; then
              read -r ow oh < <(
                niri msg -j outputs 2>/dev/null \
                  | jq -r --arg o "$output" '.[$o].logical | "\(.width) \(.height)"' 2>/dev/null
              ) || true
              if [ -n "''${ow:-}" ] && [ "''${ow}" != "null" ]; then
                W="$ow"
                H="$oh"
              else
                echo "steam-gamescope: output '$output' not found via niri; using default size" >&2
              fi
            fi
          fi

          gs=(
            -W "''${W:-1920}" -H "''${H:-1080}"
            "''${prefer[@]}"
            "''${fs[@]}"
            --steam                          # embedded Steam session integration
            -o "''${GS_UNFOCUSED_FPS:-30}"   # throttle FPS when the window is unfocused
          )
          [ "''${GS_MANGO:-0}" = 1 ] && gs+=(--mangoapp)
          [ -n "''${GS_HZ:-}" ] && gs+=(-r "''${GS_HZ}")

          # Your extra gamescope flags win/extend: -f, -b, --prefer-output <conn>,
          # -F fsr|nis, -S integer|stretch, -w/-h (game res), -r (fps cap), ...
          gs+=("$@")

          if [ "''${GS_DESKTOP:-0}" = 1 ]; then
            steam_args=()
          else
            steam_args=(-gamepadui)
          fi

          export PULSE_SINK="''${PULSE_SINK:-games}"  # match steam-niri-launch audio routing
          exec ${pkgs.gamescope}/bin/gamescope "''${gs[@]}" -- steam "''${steam_args[@]}"
        '';

        steam-gamescope-desktop = pkgs.makeDesktopItem {
          name = "steam-gamescope";
          desktopName = "Steam (gamescope)";
          comment = "Steam Big Picture in a nested, movable/resizable gamescope window";
          exec = "steam-gamescope";
          icon = "steam";
          terminal = false;
          categories = [ "Game" ];
        };
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
          steam-gamescope # `steam-gamescope` wrapper (defined in let above)
          steam-gamescope-desktop # "Steam (gamescope)" app-launcher entry
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
          extraCompatPackages = [
            pkgs.proton-ge-bin
            proton-cachyos # pinned known-good build (see let-binding above)
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
