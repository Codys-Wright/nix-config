# T3 Code — the self-updating server (t3code.service) and the desktop app.
#
# Both halves update themselves, so neither is pinned in nix:
#   - Server: `t3 service install` writes ~/.config/systemd/user/t3code.service
#     whose launcher picks ~/.t3/runtime/service-state.json's activeVersion.
#   - Desktop: the upstream AppImage, kept at a stable writable path so
#     electron-updater replaces it in place. `t3code-desktop` only downloads
#     it when missing.
#
# A T3 home admits one server (exclusive lock on server-owner.sqlite) and the
# desktop always runs its own backend, so the desktop gets its own home
# (~/.t3-desktop) and pairs with the background service as an environment.
{ fleet, ... }:
{
  fleet.coding._.t3code = {
    description = "T3 Code desktop app (self-updating AppImage) + host libraries for T3's headless browser";

    homeManager =
      { pkgs, lib, ... }:
      let
        t3code-desktop = pkgs.writeShellApplication {
          name = "t3code-desktop";
          runtimeInputs = with pkgs; [
            appimage-run
            binutils
            coreutils
            curl
            gawk
            openssl
            squashfsTools
          ];
          text = ''
            dir="''${XDG_DATA_HOME:-$HOME/.local/share}/t3code"
            img="$dir/T3-Code.AppImage"
            icon="''${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps/t3code.png"
            base=https://github.com/pingdotgg/t3code/releases/latest/download

            if [ ! -s "$img" ]; then
              mkdir -p "$dir"
              meta=$(curl -fsSL "$base/latest-linux.yml")
              file=$(awk '/^path:/ { print $2 }' <<<"$meta")
              sha=$(awk '/^sha512:/ { print $2 }' <<<"$meta")
              echo "t3code-desktop: downloading $file" >&2
              curl -fL --progress-bar -o "$img.part" "$base/$file"
              got=$(openssl dgst -sha512 -binary "$img.part" | base64 -w0)
              if [ "$got" != "$sha" ]; then
                rm -f "$img.part"
                echo "t3code-desktop: sha512 mismatch for $file" >&2
                exit 1
              fi
              chmod +x "$img.part"
              mv "$img.part" "$img"
            fi

            # Icon for the desktop entry, pulled straight from the squashfs.
            if [ ! -s "$icon" ]; then
              offset=$(LC_ALL=C readelf -h "$img" | awk 'NR==13{o=$5} NR==18{s=$5} NR==19{n=$5} END{print o+s*n}')
              png=usr/share/icons/hicolor/512x512/apps/t3code.png
              tmp=$(mktemp -d)
              if unsquashfs -q -f -d "$tmp" -o "$offset" "$img" "$png" >/dev/null; then
                install -Dm644 "$tmp/$png" "$icon"
              fi
              rm -rf "$tmp"
            fi

            # appimage-run unpacks every version into its cache; drop T3 Code's
            # stale ones (other AppImages share the directory).
            cache="''${XDG_CACHE_HOME:-$HOME/.cache}/appimage-run"
            current=$(sha256sum "$img" | awk '{ print $1 }')
            for d in "$cache"/*/; do
              d=''${d%/}
              [ "''${d##*/}" = "$current" ] && continue
              [ -e "$d/t3code.desktop" ] && rm -rf "$d"
            done

            export T3CODE_HOME="''${T3CODE_DESKTOP_HOME:-$HOME/.t3-desktop}"
            exec appimage-run "$img" "$@"
          '';
        };
      in
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [
          t3code-desktop
          # The app icon (from the AppImage) ships with the config, so docks and
          # launchers show it before t3code-desktop's first run extracts its own.
          (pkgs.runCommand "t3code-icon" { } ''
            install -Dm644 ${./_t3code/t3code.png} $out/share/icons/hicolor/512x512/apps/t3code.png
          '')
        ];

        xdg.desktopEntries.t3code = {
          name = "T3 Code";
          genericName = "Coding agents";
          exec = "t3code-desktop %U";
          icon = "t3code";
          terminal = false;
          categories = [ "Development" ];
          mimeType = [ "x-scheme-handler/t3code" ];
          settings.StartupWMClass = "t3code";
        };
      };

    # The server's headless browser is a downloaded chrome-headless-shell and
    # Codex wants bubblewrap on PATH; both run outside any FHS env, so the
    # Chrome/Electron library set goes into nix-ld (the list mirrors upstream's
    # `t3 browser setup` apt packages, which can't run on NixOS).
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        programs.appimage = {
          enable = true;
          binfmt = true;
        };

        programs.nix-ld = {
          enable = true;
          libraries = with pkgs; [
            alsa-lib
            at-spi2-atk
            at-spi2-core
            cairo
            cups
            dbus
            expat
            glib
            gtk3
            libdrm
            libgbm
            libxcb
            libxcomposite
            libxdamage
            libxext
            libxfixes
            libxkbcommon
            libxrandr
            libxshmfence
            libx11
            nspr
            nss
            pango
            systemd # libudev
          ];
        };

        environment.systemPackages = [ pkgs.bubblewrap ];
      };
  };
}
