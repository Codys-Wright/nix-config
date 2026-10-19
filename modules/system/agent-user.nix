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
            ssh-keys.fleet.starcommandAgent
          ];
          # What Hermes's tools expect on PATH when its terminal backend runs
          # here over SSH (the same set its own package wraps in, plus the
          # usual agent CLI kit).
          packages = with pkgs; [
            nodejs
            ffmpeg
            ripgrep
            fd
            git
            gh
            jq
            uv
            python3
            curl
            wget
            unzip
            file
            tree
          ];
        };

        # Hermes multiplexes every session to this host over one SSH
        # connection (ControlMaster); sshd's default MaxSessions 10 would cap
        # concurrently running commands at ten.
        services.openssh.settings.MaxSessions = 64;

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
