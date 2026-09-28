# Explicit den.schema option declarations required by strict mode
# (modules/den/strict.nix). Strict throws on any key set on a den entity
# without a declaration — the fix is always to declare the option here,
# never to delete the data that set it.
{ lib, ... }:
{
  # hosts/<name>.deployment — where a host is reached for deployment.
  # Read from den.hosts by modules/flake/deploy-targets.nix.
  den.schema.host.options.deployment = lib.mkOption {
    type = lib.types.submodule (
      { config, ... }:
      {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = config.ip != null;
            defaultText = "ip != null";
            description = "Deploy this host (deploy-rs / just deploy); on whenever ip is set";
          };
          ip = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Target address for deploy-rs";
          };
          sshUser = lib.mkOption {
            type = lib.types.str;
            default = "root";
            description = "SSH user deploy-rs connects as";
          };
          sshPort = lib.mkOption {
            type = lib.types.port;
            default = 22;
            description = "SSH port deploy-rs connects to";
          };
        };
      }
    );
    default = { };
    description = "deploy-rs deployment settings for this host";
  };

  # hosts/<name>.timeZone — the host's IANA timezone (NixOS; null = UTC).
  den.schema.host.options.timeZone = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "America/Los_Angeles";
    description = "IANA timezone for the host (sets time.timeZone on NixOS)";
  };
  den.schema.host.includes = [
    (
      { host, ... }:
      {
        name = "entity-timezone/${host.name}";
        nixos = lib.mkIf (host.timeZone != null) { time.timeZone = host.timeZone; };
      }
    )
  ];

  # hosts/<name>.users.<user>.extraGroups — per-host groups for one user,
  # forwarded to users.users.<name> through the `user` class below.
  den.schema.user.options.extraGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Additional Unix groups for the user on this host";
  };
  den.schema.user.includes = [
    (
      { host, user, ... }:
      {
        name = "entity-extra-groups/${user.userName}";
      }
      # NixOS only — nix-darwin's users.users has no extraGroups.
      // lib.optionalAttrs ((host.class or null) == "nixos") {
        user.extraGroups = user.extraGroups;
      }
    )
  ];
}
