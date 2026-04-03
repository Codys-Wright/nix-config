{
  FTS,
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
                hostname = "192.168.0.102";
                user = "root";
                identityFile = "~/.ssh/starcommand-deploy";
              };
              "THEBATTLESHIP" = {
                host = "THEBATTLESHIP thebattleship thebattleship-1";
                hostname = "thebattleship-1";
                user = "cody";
                identityFile = "~/.ssh/id_ed25519";
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
        # Home-manager backup system
        den.aspects.hm-backup

        # ── Browsers ──
        <FTS.apps/browsers/brave>
        <FTS.apps/browsers/firefox>
        <FTS.apps/browsers/firefox_webapps>

        # ── Communication ──
        <FTS.apps/communications/discord>
        <FTS.apps/communications/telegram>

        # ── Notes ──
        <FTS.apps/notes/obsidian>

        # ── Misc apps ──
        <FTS.apps/misc/localsend>
        <FTS.apps/misc/flameshot>
        <FTS.apps/misc/appimage>

        # ── AI ──
        <FTS.apps/ai/openclaw>

        # ── CLI tools ──
        <FTS.coding/cli>
        <FTS.coding/cli/atuin>
        <FTS.coding/cli/btop>
        <FTS.coding/cli/direnv>
        <FTS.coding/cli/eza>
        <FTS.coding/cli/fzf>
        <FTS.coding/cli/just>
        <FTS.coding/cli/sesh>
        <FTS.coding/cli/yazi>
        <FTS.coding/cli/zoxide>

        # ── Editors ──
        <FTS.coding/editors/cursor>
        <FTS.coding/editors/nvf>
        <FTS.coding/editors/lazyvim>
        <FTS.coding/editors/zed>

        # ── Terminals ──
        <FTS.coding/terminals/ghostty>
        <FTS.coding/terminals/kitty>
        <FTS.coding/terminals/tmux>
        <FTS.coding/terminals/zellij>
        <FTS.coding/terminals/wezterm>

        # ── Shells ──
        <FTS.coding/shells/fish>
        <FTS.coding/shells/zsh>
        <FTS.coding/shells/nushell>
        <FTS.coding/shells/oh-my-posh>

        # ── Languages ──
        <FTS.coding/lang/rust>
        <FTS.coding/lang/typescript>
        <FTS.coding/lang/python>

        # ── Dev tools ──
        <FTS.coding/tools/git>
        <FTS.coding/tools/lazygit>
        <FTS.coding/tools/opencode>
        <FTS.coding/tools/dev-tools>
        <FTS.coding/tools/containers/podman>

        # ── User configuration ──
        (<FTS.user/password> {
          method = "hashed";
          value = "$6$0C2OSNBUmq/740g7$VfDQJvfYnxCwlV/KlmAIz.z5jYpIVc7Qa.1pzL/Fu3UGprNVLSKljI310/gyeCiYOPhJ.TVijW62wTmY54Ols1";
        })
        <den/primary-user>
        (<den/user-shell> "fish")

        # ── Cody-specific ──
        cody.dots
        cody.fish

        # ── Fonts ──
        <FTS/apple-fonts>

        # ── VPN ──
        <FTS/hardware/networking/tailscale>
      ];
    };
  };
}
