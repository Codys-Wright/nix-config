# Typed per-host tunables for fleet aspects (den "aspect settings" pattern).
#
# An aspect declares options under `settings` and reads them from `host`:
#
#   fleet.desktop = {
#     settings.session = lib.mkOption { type = lib.types.str; default = "niri"; };
#     nixos = { host, ... }: { … host.settings.desktop.session … };
#   };
#
# and a host overrides them on its entry:
#
#   den.hosts.x86_64-linux.igloo.settings.desktop.session = "gnome";
#
# Use settings for knobs that vary per host; plain constants otherwise.
# Only one `settings` definition per aspect — reserved keys don't merge.
{ den, lib, ... }:
{
  den.reservedKeys = [ "settings" ];

  den.schema.host.imports = [
    {
      options.settings = lib.mkOption {
        type = import ./_settings-type.nix { inherit den lib; };
        default = { };
        description = "Per-aspect typed settings (paths mirror the fleet aspect tree)";
      };
    }
  ];
}
