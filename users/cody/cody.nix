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
        aspect = "cody";
      };

      # NixOS home configuration
      x86_64-linux.cody = {
        userName = "cody";
        aspect = "cody";
      };
    };

    # Cody user aspect - includes user-specific configurations
    aspects.cody = {
      description = "Cody user configuration";

      homeManager =
        { ... }:
        {
          # SSH host aliases for easy access to deployed machines
          programs.ssh = {
            enable = true;
            matchBlocks = {
              "starcommand" = {
                hostname = "192.168.0.106";
                user = "starcommand";
                identityFile = "~/.ssh/starcommand-deploy";
              };
              "starcommand-root" = {
                host = "starcommand-root";
                hostname = "192.168.0.106";
                user = "root";
                identityFile = "~/.ssh/starcommand-deploy";
              };
              "THEBATTLESHIP" = {
                host = "THEBATTLESHIP thebattleship thebattleship-1";
                hostname = "thebattleship-1";
                user = "cody";
                identityFile = "~/.ssh/id_ed25519";
              };
              "electric" = {
                hostname = "100.65.190.11";
                user = "root";
              };
            };
          };

          # Firefox WebApps configuration
          programs.firefox.webapps = {
            # YouTube
            youtube = {
              url = "https://youtube.com";
              id = 1;
              name = "YouTube";
              icon = "youtube";
              categories = [
                "AudioVideo"
                "Video"
              ];
              theme = "dark";
            };

            # ChatGPT
            chatgpt = {
              url = "https://chatgpt.com";
              id = 2;
              name = "ChatGPT";
              icon = "chatgpt";
              categories = [
                "Office"
                "Utility"
              ];
              theme = "dark";
            };

            # Gmail
            gmail = {
              url = "https://gmail.com";
              id = 3;
              name = "Gmail";
              icon = "gmail";
              categories = [
                "Office"
                "Email"
              ];
              theme = "light";
            };
          };
        };

      includes = [
        den.aspects.hm-backup

        <fleet/apps>
        <fleet.apps/browsers/firefox_webapps>
        (<fleet.apps/default-file-manager> "nautilus")
        (<fleet.apps/default-browser> "brave")

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

        cody.dots
        cody.fish
        <fleet/apple-fonts>
        <fleet.coding/ghidra>
        <fleet.coding._.tools/game-dev>
        <fleet.hardware._.networking/tailscale>
        <fleet.gaming/proton>
      ];
    };
  };
}
