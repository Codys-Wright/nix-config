{
  inputs,
  den,
  pkgs,
  lib,
  FTS,
  __findFile,
  ...
}:
{
  den = {
    homes = {
      # Darwin (macOS) home configuration
      aarch64-darwin.starcommand = {
        userName = "starcommand";
        aspect = "starcommand";
      };

      # NixOS home configuration
      x86_64-linux.starcommand = {
        userName = "starcommand";
        aspect = "starcommand";
      };
    };

    # starcommand user aspect
    # This is a service user for self-hosting infrastructure, not a personal user
    # Any host that includes this user automatically gets all self-hosting services
    #
    # Note: Hosts including this user should set their instantiate function to use
    # selfhostblocks' patched nixpkgs:
    #   instantiate = args: inputs.selfhostblocks.lib.${system}.patchedNixpkgs.nixosSystem (args // { inherit system; });
    aspects.starcommand = {
      description = "Self-hosting services user (starcommand)";

      includes = [
        # Home-manager backup system
        den.aspects.hm-backup

        # Basic user setup with admin privileges (sets initialPassword = "password")
        <FTS.apps/browsers>
        <FTS.apps/misc>

        <FTS.coding/cli>
        <FTS.coding/editors>
        <FTS.coding/terminals>
        <FTS.coding/shells>
        <FTS.coding/lang>
        <FTS.coding/tools>

        <den/primary-user> # Admin privileges and user configuration
        <FTS.user/autologin> # Autologin configuration (enabled when display manager is present)

        (<den/user-shell> "fish") # Set fish as default shell

        # Theme and fonts
        # FTS.mactahoe
        # FTS.apple-fonts
        # FTS.stylix

        # Desktop environment
        <FTS.desktop/environment/hyprland>

        # Include the FTS.selfhost module which has all the SelfHostBlocks configuration
        (FTS.selfhost { })
      ];

      # Override hypridle to prevent system suspend (this is a server)
      homeManager = {
        services.hypridle.settings.listener = lib.mkForce [
          {
            timeout = 300; # 5 minutes
            on-timeout = "loginctl lock-session"; # Lock screen
          }
          {
            timeout = 330; # 5.5 minutes
            on-timeout = "hyprctl dispatch dpms off"; # Turn off display
            on-resume = "hyprctl dispatch dpms on"; # Turn on display
          }
          # Removed suspend listener - server should never sleep
        ];
      };
    };
  };
}
