{ ... }:
{
  cody.opendeck = {
    description = "Cody's mutable OpenDeck layout/config, stored in the flake repo";

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        configRoot = "${config.home.homeDirectory}/.flake/users/cody/opendeck/config";
        opendeck = pkgs.callPackage ../../../packages/opendeck/opendeck.nix { };
        syncConfig = pkgs.writeShellScript "sync-opendeck-config" ''
          set -eu

          mkdir -p "${configRoot}"
          for file in settings.json applications.json; do
            if [ -f "$HOME/.config/opendeck/$file" ]; then
              install -m 0644 "$HOME/.config/opendeck/$file" "${configRoot}/$file"
            fi
          done
        '';
        niriProfileSwitcher = pkgs.writeShellScript "opendeck-niri-profile-switcher" ''
          set -eu

          applications_file="$HOME/.config/opendeck/applications.json"
          websocket="ws://127.0.0.1:57116"
          bridge_uuid="opendeck_alternative_elgato_implementation"

          focused_app() {
            ${lib.getExe pkgs.niri} msg -j focused-window 2>/dev/null | ${lib.getExe pkgs.jq} -r '.app_id // empty' 2>/dev/null || true
          }

          switch_profiles() {
            app="$1"

            if [ ! -f "$applications_file" ]; then
              return
            fi

            ${lib.getExe pkgs.jq} -c --arg app "$app" '
              (.[$app] // .opendeck_default // {}) | to_entries[]
            ' "$applications_file" | while IFS= read -r entry; do
              device="$(printf '%s\n' "$entry" | ${lib.getExe pkgs.jq} -r '.key')"
              profile="$(printf '%s\n' "$entry" | ${lib.getExe pkgs.jq} -r '.value')"

              {
                printf '{"event":"registerPlugin","uuid":"%s"}\n' "$bridge_uuid"
                printf '{"event":"switchProfile","device":"%s","profile":"%s"}\n' "$device" "$profile"
              } | ${pkgs.coreutils}/bin/timeout 2s ${lib.getExe pkgs.websocat} -q "$websocket" >/dev/null 2>&1 || true
            done
          }

          last_app=""

          app="$(focused_app)"
          if [ -n "$app" ]; then
            switch_profiles "$app"
            last_app="$app"
          fi

          while true; do
            app="$(focused_app)"
            if [ -n "$app" ] && [ "$app" != "$last_app" ]; then
              switch_profiles "$app"
              last_app="$app"
            fi
            sleep 0.5
          done
        '';
      in
      {
        home.activation.seedOpenDeckConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          mkdir -p "$HOME/.config/opendeck"
          for file in settings.json applications.json; do
            if [ -f "${configRoot}/$file" ]; then
              install -m 0644 "${configRoot}/$file" "$HOME/.config/opendeck/$file"
            fi
          done
        '';

        xdg.configFile."opendeck/profiles" = {
          force = true;
          source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/profiles";
        };

        xdg.configFile."opendeck/images" = {
          force = true;
          source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/images";
        };

        systemd.user.services.opendeck-config-sync = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Sync OpenDeck JSON config back to the flake repo";

          Service = {
            Type = "oneshot";
            ExecStart = syncConfig;
          };
        };

        systemd.user.paths.opendeck-config-sync = lib.mkIf pkgs.stdenv.isLinux {
          Unit.Description = "Watch OpenDeck JSON config for repo sync";

          Path = {
            PathChanged = [
              "%h/.config/opendeck"
              "%h/.config/opendeck/settings.json"
              "%h/.config/opendeck/applications.json"
            ];
            Unit = "opendeck-config-sync.service";
          };

          Install.WantedBy = [ "default.target" ];
        };

        systemd.user.services.opendeck = lib.mkIf pkgs.stdenv.isLinux {
          Unit = {
            Description = "OpenDeck Stream Deck controller";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = lib.getExe opendeck;
            Restart = "always";
            RestartSec = "5s";
            Environment = [
              "GDK_BACKEND=wayland,x11"
            ];
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };

        systemd.user.services.opendeck-niri-profile-switcher = lib.mkIf pkgs.stdenv.isLinux {
          Unit = {
            Description = "Switch OpenDeck profiles from Niri focus changes";
            After = [
              "graphical-session.target"
              "opendeck.service"
            ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = niriProfileSwitcher;
            Restart = "always";
            RestartSec = "2s";
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
