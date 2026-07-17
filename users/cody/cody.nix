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

      homeManager =
        { ... }:
        {
          systemd.user.startServices = "suggest";
        };

      includes = [
        den.aspects.hm-backup

        # SSH host aliases + peer-reachability tiers (users/cody/modules/ssh.nix)
        cody.ssh
        # Firefox WebApps definitions (users/cody/modules/webapps.nix)
        cody.webapps

        # Music production plugins (VST3/CLAP) and the ~/.vst3/nixos,
        # ~/.clap/nixos, ~/.lv2/nixos plugin-dir symlinks DAWs scan —
        # homeManager-only aspects; host-level includes of
        # <fleet.music/production> only reach nixos config, not per-user
        # home.packages/home.file, so both must be included here.
        <fleet.music/production/plugins>
        <fleet.music/production/environment>
        # Guitar tooling (NAM model dirs etc.) — homeManager side.
        <fleet.music._.production._.guitar>
        # Plain `reaper` (+ SWS/ReaPack) in cody's home. The aspect's
        # homeManager only routes when included in the HOME pipeline — host
        # inclusion (via <fleet.music/production>) contributes nixos only.
        <fleet.music._.production._.reaper>

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
        <fleet.hardware._.networking/tailscale>
      ];
    };
  };
}
