# Reaper DAW with extensions
# Uses reaper-flake's custom reaper derivation (v7.86) instead of nixpkgs
{
  fleet,
  inputs,
  ...
}:
{
  flake-file.inputs.reaper-flake.url = "github:FastTrackStudios/reaper-flake";
  flake-file.inputs.reaper-flake.inputs.nixpkgs.follows = "nixpkgs";

  fleet.music._.production._.reaper = {
    description = "Reaper digital audio workstation with SWS and ReaPack extensions (v7.86 via reaper-flake)";

    # reaper-flake's reaper (and the SWS/ReaPack extensions, which ship
    # x86_64-linux .so files) declare linux-only meta.platforms, so the whole
    # aspect is omitted on darwin — otherwise the shared cody home aspect fails
    # to evaluate on aarch64-darwin (voyager). mkIf, not lib.optionalAttrs:
    # optionalAttrs forces the config<-args<-config cycle into infinite
    # recursion, same reason the other linux-only guards use mkIf.
    homeManager =
      { pkgs, lib, ... }:
      let
        reaperPkgs = inputs.reaper-flake.lib.mkReaperPackages {
          inherit pkgs;
          cfg = inputs.reaper-flake.presets.full // {
            headless.enable = false;
            # Global menu: REAPER's menu goes to Loft's top bar (DBusMenu) and
            # the in-window menu bar hides while a registrar is up.
            extensions = inputs.reaper-flake.presets.full.extensions // {
              appmenu = true;
            };
          };
        };

        # Realtime priority for REAPER's audio worker threads (reaper/mediaafx,
        # reaper/livefx). With jack_rtprio=-1 (REAPER's "don't") they run
        # SCHED_OTHER and any big build starves them → xruns / glitchy
        # playback. At 80 they run SCHED_RR 79/80: below PipeWire's data loop
        # (FIFO 83) and statime (82), within cody's RTPRIO rlimit (95).
        # alsa_rtprio is the same knob for REAPER's ALSA backend.
        #
        #
        # JACK MIDI slots: on the JACK backend REAPER makes a fixed number of
        # MIDI ports (64 by default) and fills them with hardware ports in
        # enumeration order; every unfilled slot is a "MIDI Input N" row in
        # Preferences → MIDI Inputs. 32 covers the studio's ~26 hardware ports
        # (mioXM 16, S88 3, Axe-Fx, X-Touch 2, MiniFuse, Sparrow, BLE, Through)
        # without the wall of placeholders. Raise it if a device goes missing.
        #
        # REAPER owns reaper.ini and rewrites it on exit, so home-manager
        # can't manage the file; instead the launcher pins these keys in the
        # [reaper] section before every start (the -cfgfile one if given).
        pinnedIni = {
          jack_rtprio = 80;
          alsa_rtprio = 80;
          jack_midiins = 32;
          jack_midiouts = 32;
        };
        pinnedLines = lib.concatStringsSep "\\n" (
          lib.mapAttrsToList (k: v: "${k}=${toString v}") pinnedIni
        );
        pinnedRe = "^(${lib.concatStringsSep "|" (lib.attrNames pinnedIni)})=";
        reaperRt = pkgs.symlinkJoin {
          name = "reaper-rt-${reaperPkgs.reaper.version or "wrapped"}";
          paths = [ reaperPkgs.reaper ];
          postBuild = ''
            rm $out/bin/reaper
            cat > $out/bin/reaper <<'EOF'
            #!${pkgs.runtimeShell}
            ini="''${XDG_CONFIG_HOME:-$HOME/.config}/REAPER/reaper.ini"
            prev=""
            for a in "$@"; do
              [ "$prev" = "-cfgfile" ] && ini="$a"
              prev="$a"
            done
            if [ -f "$ini" ] && [ -w "$ini" ]; then
              tmp="$ini.pinned.$$"
              ${pkgs.gawk}/bin/awk '
                function emit() { if (!done) { print "${pinnedLines}"; done = 1 } }
                /^\[/ { if (sec) emit(); sec = (tolower($0) == "[reaper]") }
                sec && /${pinnedRe}/ { next }
                { print }
                END { if (sec) emit() }
              ' "$ini" > "$tmp" && mv "$tmp" "$ini" || rm -f "$tmp"
            fi
            exec ${reaperPkgs.reaper}/bin/reaper "$@"
            EOF
            chmod +x $out/bin/reaper
          '';
        };
      in
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        home.packages = [
          reaperRt
          pkgs.reaper-sws-extension
          pkgs.reaper-reapack-extension
        ];

        # Symlink REAPER extensions to UserPlugins directory.
        # force = true: cody already has real ReaPack-installed .so files here
        # (from before this aspect routed to the home); let home-manager own
        # them with the nix-pinned builds instead of erroring on the clobber.
        home.file.".config/REAPER/UserPlugins/reaper_sws-x86_64.so" = {
          source = "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so";
          force = true;
        };
        home.file.".config/REAPER/UserPlugins/reaper_appmenu-x86_64.so".source =
          "${reaperPkgs.appmenu}/UserPlugins/reaper_appmenu-x86_64.so";
        home.file.".config/REAPER/UserPlugins/reaper_reapack-x86_64.so" = {
          source = "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so";
          force = true;
        };

        # Symlink SWS Python scripts
        home.file.".config/REAPER/Scripts/sws_python.py".source =
          "${pkgs.reaper-sws-extension}/Scripts/sws_python.py";
        home.file.".config/REAPER/Scripts/sws_python64.py".source =
          "${pkgs.reaper-sws-extension}/Scripts/sws_python64.py";
      };
  };
}
