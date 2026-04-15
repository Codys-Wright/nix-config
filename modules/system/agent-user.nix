# Agent user — shared AI/automation user across the fleet
# Used by Hermes Agent and other AI tools for remote operations
# SSH key is the starcommand deploy key
{ fleet, ssh-keys, ... }:
{
  fleet.system._.agent-user = {
    description = "AI agent user for automation and remote operations";

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        users.users.agent = {
          isNormalUser = true;
          description = "AI Agent";
          home = "/home/agent";
          createHome = true;
          shell = pkgs.bashInteractive;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [
            ssh-keys.fleet.starcommand
          ];
        };

        # Passwordless sudo for the agent user
        security.sudo.extraRules = [
          {
            users = [ "agent" ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      };
  };
}
