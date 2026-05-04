{
  fleet,
  den,
  __findFile,
  ...
}:
let
  braveAllowedDomains = [
    # YouTube
    "youtube.com"
    "www.youtube.com"
    "m.youtube.com"
    "music.youtube.com"
    "youtu.be"
    "ytimg.com"
    "i.ytimg.com"
    "s.ytimg.com"
    "googlevideo.com"
    "ggpht.com"
    "youtubei.googleapis.com"

    # Guitar/tab sites
    "ultimate-guitar.com"
    "www.ultimate-guitar.com"
    "tabs.ultimate-guitar.com"
    "songsterr.com"
    "www.songsterr.com"

    # Search engines
    "search.brave.com"
    "brave.com"
    "duckduckgo.com"
    "www.duckduckgo.com"
    "startpage.com"
    "www.startpage.com"
    "google.com"
    "www.google.com"
    "googleapis.com"
    "gstatic.com"
    "googleusercontent.com"
    "bing.com"
    "www.bing.com"
  ];

  braveHostRules =
    "MAP * ~NOTFOUND, "
    + builtins.concatStringsSep ", " (map (domain: "EXCLUDE ${domain}") braveAllowedDomains);

  mkBraveChild =
    { pkgs }:
    pkgs.writeShellApplication {
      name = "brave-child";
      runtimeInputs = [
        pkgs.brave
        pkgs.coreutils
      ];
      text = ''
        set -euo pipefail

        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/brave-child"
        today="$(${pkgs.coreutils}/bin/date +%F)"
        state_file="$state_dir/usage-$today"
        profile_dir="$state_dir/profile"
        limit_seconds=3600

        mkdir -p "$state_dir"

        used=0
        if [ -f "$state_file" ]; then
          used="$(${pkgs.coreutils}/bin/cat "$state_file" 2>/dev/null || echo 0)"
        fi

        if [ "$used" -ge "$limit_seconds" ]; then
          echo "Daily Brave time limit reached. Try again tomorrow."
          exit 1
        fi

        remaining=$((limit_seconds - used))
        start="$(${pkgs.coreutils}/bin/date +%s)"

        timeout --foreground --kill-after=10s "''${remaining}s" brave-browser \
          --user-data-dir="$profile_dir" \
          --host-resolver-rules='${braveHostRules}' \
          "$@"
        status=$?

        end="$(${pkgs.coreutils}/bin/date +%s)"
        elapsed=$((end - start))
        new_used=$((used + elapsed))

        printf '%s\n' "$new_used" > "$state_file"
        exit "$status"
      '';
    };

  mkDisabledLauncher =
    {
      pkgs,
      name,
      label,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        echo "${label} is disabled for Joshua."
        exit 1
      '';
    };
in
{
  den.homes.x86_64-linux.joshua = {
    userName = "joshua";
  };

  den.aspects.joshua = {
    description = "Joshua user — browser-only child account";

    includes = [
      den.aspects.hm-backup
      <den/primary-user>

      # Browser only
      <fleet.apps/browsers/brave>
      (<fleet.apps/default-browser> "brave")
    ];

    nixos =
      { lib, pkgs, ... }:
      {
        users.users.joshua = {
          isNormalUser = true;
          description = "Joshua";
          shell = pkgs.bashInteractive;
          extraGroups = lib.mkForce [
            "audio"
            "video"
            "input"
            "networkmanager"
          ];
          hashedPassword = "$6$Ws1Duox8/lqfT8ig$hVoe.bJu67HhMce9RGT6qycWSaLgPaITbLGB/jNn6uN5zp2Bgtbf.alg2zHmICmzjHjnW9ZIhXhD0.6dHscr7/";
        };

        # Keep Joshua's writable home on a separate bind mount with noexec/nodev/nosuid
        # so downloaded AppImages and other portable binaries cannot be executed from
        # his home directory.
        fileSystems."/home/joshua" = {
          device = "/persist/home/joshua";
          fsType = "none";
          options = [
            "bind"
            "noexec"
            "nodev"
            "nosuid"
            "x-systemd.requires-mounts-for=/persist"
          ];
        };

        systemd.services."persist-home-joshua-init" = {
          description = "Create /persist/home/joshua before bind mount";
          wantedBy = [ "home-joshua.mount" ];
          before = [ "home-joshua.mount" ];
          after = [ "persist.mount" ];
          unitConfig.RequiresMountsFor = "/persist";
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p /persist/home/joshua
            chown joshua:users /persist/home/joshua
            chmod 0700 /persist/home/joshua
          '';
        };

        # Allow Joshua to log in only between 08:00 and 22:00.
        environment.etc."security/time.conf".text = ''
          sddm ; * ; joshua ; Al0800-2200
        '';

        security.pam.services.sddm.text = ''
          auth      substack      login
          account   include       login
          password  substack      login
          session   include       login
          account   required      pam_time.so conffile=/etc/security/time.conf
        '';

        services.timekpr = {
          enable = true;
          adminUsers = [ "cody" ];
        };

        systemd.services.timekpr-joshua-setup = {
          description = "Configure Timekpr rules for Joshua";
          wantedBy = [ "multi-user.target" ];
          after = [ "timekpr.service" ];
          requires = [ "timekpr.service" ];
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            ${pkgs.timekpr}/bin/timekpra --setalloweddays joshua '1;2;3;4;5;6;7'
            ${pkgs.timekpr}/bin/timekpra --setallowedhours joshua ALL '8;9;10;11;12;13;14;15;16;17;18;19;20;21'
            ${pkgs.timekpr}/bin/timekpra --setlockouttype joshua terminate
            ${pkgs.timekpr}/bin/timekpra --setplaytimeenabled joshua true
            ${pkgs.timekpr}/bin/timekpra --setplaytimealloweddays joshua '1;2;3;4;5;6;7'
            ${pkgs.timekpr}/bin/timekpra --setplaytimelimits joshua '3600;3600;3600;3600;3600;3600;3600'
            ${pkgs.timekpr}/bin/timekpra --setplaytimeactivities joshua 'brave-browser[Brave Browser]'
            ${pkgs.timekpr}/bin/timekpra --setplaytimeunaccountedintervalsflag joshua false
          '';
        };

        systemd.services.joshua-curfew = {
          description = "Terminate Joshua sessions outside allowed hours";
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            hour="$(${pkgs.coreutils}/bin/date +%H)"
            if [ "$hour" -lt 8 ] || [ "$hour" -ge 22 ]; then
              ${pkgs.systemd}/bin/loginctl terminate-user joshua || true
            fi
          '';
        };

        systemd.timers.joshua-curfew = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1m";
            OnUnitActiveSec = "1m";
            Unit = "joshua-curfew.service";
          };
        };
      };

    homeManager =
      { pkgs, ... }:
      let
        braveChildPkg = mkBraveChild { inherit pkgs; };
      in
      {
        home.packages = [
          braveChildPkg
          (mkDisabledLauncher {
            inherit pkgs;
            name = "plasma-discover";
            label = "KDE Discover";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "ghostty";
            label = "Ghostty";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "ghidra";
            label = "Ghidra";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "obsidian";
            label = "Obsidian";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "virt-manager";
            label = "Virtual Machine Manager";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "nix";
            label = "Nix package manager";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "nix-shell";
            label = "Nix shell";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "nix-env";
            label = "Nix profile manager";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "nix-build";
            label = "Nix build";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "nix-store";
            label = "Nix store";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "nix-collect-garbage";
            label = "Nix garbage collection";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "podman";
            label = "Podman";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "docker";
            label = "Docker";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "docker-compose";
            label = "Docker Compose";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "podman-compose";
            label = "Podman Compose";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "buildah";
            label = "Buildah";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "virt-manager";
            label = "Virtual Machine Manager";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "curl";
            label = "curl";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "wget";
            label = "wget";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "aria2c";
            label = "aria2c";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "git";
            label = "git";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "tar";
            label = "tar";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "unzip";
            label = "unzip";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "xz";
            label = "xz";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "python3";
            label = "python3";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "pipx";
            label = "pipx";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "node";
            label = "node";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "npm";
            label = "npm";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "pnpm";
            label = "pnpm";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "yarn";
            label = "yarn";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "go";
            label = "go";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "cargo";
            label = "cargo";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "rustc";
            label = "rustc";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "gcc";
            label = "gcc";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "g++";
            label = "g++";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "clang";
            label = "clang";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "make";
            label = "make";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "cmake";
            label = "cmake";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "meson";
            label = "meson";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "ninja";
            label = "ninja";
          })
          (mkDisabledLauncher {
            inherit pkgs;
            name = "skopeo";
            label = "skopeo";
          })
        ];

        xdg.desktopEntries.brave-browser = {
          name = "Brave Browser";
          comment = "Joshua's browser-limited Brave profile";
          exec = "brave-child %U";
          icon = "brave-browser";
          startupNotify = true;
          categories = [
            "Network"
            "WebBrowser"
          ];
        };

        # Hide terminal and software-center launchers from the desktop app menu.
        xdg.desktopEntries.konsole = {
          name = "Konsole";
          noDisplay = true;
        };
        xdg.desktopEntries."org.kde.konsole" = {
          name = "Konsole";
          noDisplay = true;
        };
        xdg.desktopEntries."org.kde.discover" = {
          name = "Discover";
          noDisplay = true;
        };
        xdg.desktopEntries."org.kde.discover.flatpak" = {
          name = "Discover Flatpak";
          noDisplay = true;
        };
        xdg.desktopEntries."org.kde.discover.notifier" = {
          name = "Discover Notifier";
          noDisplay = true;
        };
        xdg.desktopEntries."org.kde.discover.snap" = {
          name = "Discover Snap";
          noDisplay = true;
        };
        xdg.desktopEntries."org.kde.discover.urlhandler" = {
          name = "Discover URL Handler";
          noDisplay = true;
        };
        xdg.desktopEntries."com.mitchellh.ghostty" = {
          name = "Ghostty";
          noDisplay = true;
        };
        xdg.desktopEntries.ghidra = {
          name = "Ghidra";
          noDisplay = true;
        };
        xdg.desktopEntries.obsidian = {
          name = "Obsidian";
          noDisplay = true;
        };
        xdg.desktopEntries."virt-manager" = {
          name = "Virtual Machine Manager";
          noDisplay = true;
        };

        # Timekpr client warnings for Joshua: 15m, 5m, and 1m remaining.
        home.file.".config/timekpr/timekpr.conf".text = ''
          [CONFIG]
          LOG_LEVEL = 1
          SHOW_LIMIT_NOTIFICATION = True
          SHOW_ALL_NOTIFICATIONS = True
          SHOW_SECONDS = True
          USE_SPEECH_NOTIFICATIONS = False
          NOTIFICATION_TIMEOUT = 4
          NOTIFICATION_TIMEOUT_CRITICAL = 8
          USE_NOTIFICATION_SOUNDS = False
          NOTIFICATION_LEVELS = 900[3];300[2];60[1]
          PLAYTIME_NOTIFICATION_LEVELS = 900[3];300[2];60[1]
        '';

        # Default Joshua into Plasma on SDDM.
        home.file.".dmrc".text = ''
          [Desktop]
          Session=plasma
        '';
      };
  };
}
