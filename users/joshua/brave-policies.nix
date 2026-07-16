# Joshua's restricted desktop: time-limited, allowlisted Brave wrapper,
# disabled tool launchers, hidden desktop entries, and Plasma session default.
{ ... }:
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
  den.aspects.joshua-brave-policies = {
    description = "Joshua's restricted desktop — allowlisted time-limited Brave, disabled launchers, hidden desktop entries, Plasma default";

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

        # Default Joshua into Plasma on SDDM.
        home.file.".dmrc".text = ''
          [Desktop]
          Session=plasma
        '';
      };
  };
}
