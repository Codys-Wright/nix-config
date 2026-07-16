# Explicit den.schema option declarations required by strict mode
# (modules/flake/strict.nix). Strict throws on any key set on a den entity
# without a declaration — the fix is always to declare the option here,
# never to delete the data that set it.
{ lib, ... }:
{
  # hosts/<name>.deployment — deploy-rs wiring consumed by
  # modules/deployment/deploy.nix (ip/sshUser/sshPort per host).
  den.schema.host.options.deployment = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Deploy this host via deploy-rs";
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
    };
    default = { };
    description = "deploy-rs deployment settings for this host";
  };

  # hosts/<name>.includes — per-host default-aspect override list (beacon sets
  # `includes = []` to skip the home-manager defaults on the ISO).
  den.schema.host.options.includes = lib.mkOption {
    type = lib.types.listOf lib.types.anything;
    default = [ ];
    description = "Extra/override includes attached directly to the host entry";
  };

  # hosts/<name>.users.<user>.extraGroups — forwarded to users.users.<name>.
  den.schema.user.options.extraGroups = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Additional Unix groups for the user on this host";
  };
}
