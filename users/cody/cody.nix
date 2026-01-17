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
              # Add more hosts here as needed
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

        # Applications - all included by default
        <FTS.apps/browsers>
        <FTS.apps/communications>
        <FTS.apps/gaming>
        <FTS.apps/notes>
        <FTS.apps/misc>
        <FTS.apps/flatpaks>

        # Music production
        <FTS.music/production>

        # Coding environment - all tools included by default
        <FTS.coding/cli>
        <FTS.coding/editors>
        <FTS.coding/terminals>
        <FTS.coding/shells>
        <FTS.coding/lang>
        <FTS.coding/tools>
        # User configuration
        <FTS.user/admin> # Admin privileges and user configuration
        <FTS.user/autologin> # Autologin configuration (enabled when display manager is present)
        (<FTS.user/shell> { default = "fish"; }) # Set fish as default shell

        # Cody-specific configurations
        cody.dots
        cody.fish

        # Samba client tools for network shares
        (FTS.selfhost._.samba-client { })

        # Theme and fonts
        FTS.mactahoe
        FTS.apple-fonts
        FTS.stylix

        # Desktop environment
        <FTS.desktop/environment/hyprland>

        # Keyboard configuration (Kanata)
        <FTS.keyboard>

        # VPN
        <FTS/hardware/networking/tailscale>
      ];
    };
  };
}
