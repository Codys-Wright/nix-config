# CLIProxyAPI client: Claude Code and Codex on this host talk to the fleet's
# subscription proxy on starcommand (Codys-Wright/starcommand
# modules/services/cliproxyapi) instead of each holding its own login.
#
#   (<fleet.coding.cli/cliproxyapi-client> {
#     baseUrl = "http://10.10.10.1:8317";      # 10G fabric; LAN hosts use 192.168.1.112
#     sopsFile = "${inputs.nix-secrets}/sops/hosts/<HOST>.yaml";
#     users = { cody = "cody"; agent = "agents"; };   # unix user -> proxy key name
#   })
#
# - Each user's proxy key comes from sops (`cliproxyapi.api_keys.<key>` in the
#   host file) to /run/secrets/cliproxyapi/<user>, owned by that user, 0400.
#   The proxy's usage stats are per key, so agent work stays apart from Cody's.
# - Claude Code: a managed-settings drop-in sets ANTHROPIC_BASE_URL and an
#   apiKeyHelper that prints the calling user's key. Managed settings reach
#   every launcher (terminal, T3 Code, Paperclip), and apiKeyHelper ranks
#   above the claude.ai login, so no session falls back to a local login.
# - Codex: the system config (/etc/codex/config.toml, below the user's own)
#   selects a `cliproxyapi` provider whose bearer token comes from the same
#   file through `auth.command`.
#
# NixOS: the host must already import sops-nix (THEBATTLESHIP-sops does).
# nix-darwin: this imports sops-nix's darwin module and decrypts with the
# host SSH key.
{ inputs, ... }:
let
  keyDir = "/run/secrets/cliproxyapi";

  claudeSettings = helper: baseUrl: {
    env.ANTHROPIC_BASE_URL = baseUrl;
    apiKeyHelper = helper;
  };

  codexConfig = helper: baseUrl: ''
    # Managed by the fleet (cliproxyapi-client). ~/.codex/config.toml
    # overrides anything here.
    model_provider = "cliproxyapi"

    [model_providers.cliproxyapi]
    name = "CLIProxyAPI (starcommand)"
    base_url = "${baseUrl}/v1"
    wire_api = "responses"

    [model_providers.cliproxyapi.auth]
    command = "${helper}"
  '';
in
{
  fleet.coding._.cli._.cliproxyapi-client.__functor =
    _self:
    {
      baseUrl,
      sopsFile,
      users,
      ...
    }:
    let
      secrets =
        group:
        builtins.listToAttrs (
          map (user: {
            name = "cliproxyapi/${user}";
            value = {
              inherit sopsFile;
              key = "cliproxyapi/api_keys/${users.${user}}";
              owner = user;
              inherit group;
              mode = "0400";
            };
          }) (builtins.attrNames users)
        );
      mkHelper =
        pkgs:
        pkgs.writeShellScript "cliproxyapi-key" ''
          exec ${pkgs.coreutils}/bin/cat ${keyDir}/"$(${pkgs.coreutils}/bin/id -un)"
        '';
    in
    {
      name = "cliproxyapi-client";
      description = "Claude Code and Codex go through the fleet CLIProxyAPI on starcommand";

      nixos =
        { pkgs, ... }:
        let
          helper = mkHelper pkgs;
        in
        {
          sops.secrets = secrets "users";
          environment.etc."claude-code/managed-settings.d/50-cliproxyapi.json".text = builtins.toJSON (
            claudeSettings "${helper}" baseUrl
          );
          environment.etc."codex/config.toml".text = codexConfig "${helper}" baseUrl;
        };

      darwin =
        { lib, pkgs, ... }:
        let
          helper = mkHelper pkgs;
          dropIn = pkgs.writeText "50-cliproxyapi.json" (
            builtins.toJSON (claudeSettings "${helper}" baseUrl)
          );
          dir = "/Library/Application Support/ClaudeCode/managed-settings.d";
        in
        {
          imports = [ inputs.sops-nix.darwinModules.sops ];
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          sops.secrets = secrets "staff";
          environment.etc."codex/config.toml".text = codexConfig "${helper}" baseUrl;
          # nix-darwin only manages /etc; Claude Code's macOS managed dir is
          # under /Library.
          system.activationScripts.postActivation.text = lib.mkAfter ''
            mkdir -p "${dir}"
            ln -sfn ${dropIn} "${dir}/50-cliproxyapi.json"
          '';
        };
    };
}
