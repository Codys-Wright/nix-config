# OpenClaw AI assistant gateway
# Discord integration + systemd user service on Linux
{
  inputs,
  FTS,
  lib,
  ...
}:
{
  # Declare nix-openclaw flake input
  flake-file.inputs.nix-openclaw.url = lib.mkDefault "github:openclaw/nix-openclaw";

  FTS.apps._.ai._.openclaw = {
    description = "OpenClaw - AI assistant gateway with Discord integration";

    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          inputs.nix-openclaw.homeManagerModules.openclaw
        ];

        nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];

        programs.openclaw = {
          enable = true;

          documents = ./documents;

          # Exclude tools already managed by our flake
          excludeTools = [
            "git"
            "jq"
            "ripgrep"
            "curl"
          ];

          config = {
            auth.profiles.claude = {
              provider = "anthropic";
              mode = "oauth";
            };

            gateway = {
              mode = "local";
              auth = {
                # Read from plain file at runtime
                token = builtins.readFile /home/cody/.secrets/openclaw-gateway-token;
              };
            };

            # Discord bot channel
            channels.discord.accounts.default = {
              enabled = true;
              botToken = builtins.readFile /home/cody/.secrets/discord-bot-token;
              # FILL IN: your Discord user ID (right-click your name > Copy User ID with dev mode on)
              allowFrom = [ ]; # e.g. [ "123456789012345678" ]
              dm = {
                enabled = true;
                policy = "allowlist";
              };
            };

            # Telegram bot channel
            channels.telegram.accounts.default = {
              enabled = true;
              botToken = {
                source = "file";
                provider = "openclaw";
                id = "/home/cody/.secrets/telegram-bot-token";
              };
              allowFrom = [ ]; # Telegram user IDs (numeric) — find yours via @userinfobot
            };
          };

          # Bundled plugins
          bundledPlugins = {
            summarize.enable = true;
          };

          # systemd user service on Linux
          systemd = {
            enable = true;
            unitName = "openclaw-gateway";
          };

          instances.default = {
            enable = true;
            plugins = [ ];
          };
        };
      };
  };
}
