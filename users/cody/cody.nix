{
  fleet,
  den,
  cody,
  __findFile,
  ...
}:
{
  den = {
    homes = {
      # Darwin (macOS) home configuration
      aarch64-darwin.cody = {
        userName = "CodyWright";
      };

      # NixOS home configuration
      x86_64-linux.cody = {
        userName = "cody";
      };
    };

    # Cody user aspect - includes user-specific configurations
    aspects.cody = {
      description = "Cody user configuration";

      user.description = "cody";

      homeManager =
        { ... }:
        {
          systemd.user.startServices = "suggest";
          # Cody's own Vaultwarden identity (the fleet default is the
          # hermes agent account).
          programs.rbw.settings.email = "acodywright@gmail.com";
        };

      includes = [
        # SSH host aliases + peer-reachability tiers (users/cody/modules/ssh.nix)
        cody.ssh
        # Firefox WebApps definitions (users/cody/modules/webapps.nix)
        cody.webapps

        # Per-user music production half (REAPER, plugins, plugin-dir
        # links, guitar, Axe-Edit, Spicetify). Hosts include the system half
        # (<fleet.music/production>) separately.
        <fleet.music._.production/producer>

        <fleet/apps>
        <fleet.apps._.misc/cuteatum>
        <fleet.apps._.misc/unshuffle>
        <fleet.apps._.misc/opendeck>
        <fleet.apps/browsers/firefox_webapps>
        (<fleet.apps/default-file-manager> "nautilus")
        (<fleet.apps/default-browser> "brave")
        cody.opendeck

        (fleet.coding {
          editor = {
            default = "nvf";
          };
          terminal = {
            default = "ghostty";
          };
          shell = {
            default = "nushell";
          };
          languages = [
            "rust"
            "typescript"
            "python"
          ];
          tools = [
            "android"
            "dioxus"
            "flyctl"
            "reverse-engineering"
            "opencode"
            "podman"
          ];
        })
        (fleet.git-identity {
          name = "Cody Wright";
          email = "acodywright@gmail.com";
        })

        (<fleet.user/password> {
          method = "hashed";
          value = "$6$0C2OSNBUmq/740g7$VfDQJvfYnxCwlV/KlmAIz.z5jYpIVc7Qa.1pzL/Fu3UGprNVLSKljI310/gyeCiYOPhJ.TVijW62wTmY54Ols1";
        })
        <den/primary-user>
        <fleet.user/admin>

        cody.dots
        cody.fish
        cody.secrets
        cody.pipewire
        <fleet/apple-fonts>
        <fleet.coding/ghidra>
        <fleet.coding._.tools/game-dev>
      ];
    };
  };
}
