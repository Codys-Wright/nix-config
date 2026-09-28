# Aspect settings generator (den guides/aspect-settings), adapted to this
# fleet: it walks the `fleet` namespace and descends through `provides`/`_`,
# which is where fleet sub-aspects live (fleet.hardware._.audio._.pipewire).
# Paths drop the `_`: host.settings.hardware.audio.pipewire.clockQuantum.
#
# Plain function file — the leading underscore keeps import-tree away.
{ den, lib }:
let
  inherit (lib) mkOption types;
  inherit (den.lib.aspects.fx.keyClassification) isStructuralKey;

  # Pipeline machinery, class content or quirk data — never child aspects.
  skipKey = k: isStructuralKey k || (den.classes or { }) ? ${k} || (den.quirks or { }) ? ${k};

  # `settings` is a bare attrset of options, or a module (options/config/imports).
  reshape = raw: if raw ? options || raw ? config || raw ? imports then raw else { options = raw; };

  childNodes =
    node:
    let
      pick = lib.filterAttrs (k: v: !(skipKey k) && builtins.isAttrs v);
      provided = if node ? provides && builtins.isAttrs node.provides then pick node.provides else { };
    in
    provided // pick node;

  hasSettingsDeep =
    node:
    builtins.isAttrs node
    && (node ? settings || lib.any hasSettingsDeep (lib.attrValues (childNodes node)));

  nodeModule =
    node:
    let
      own = reshape (node.settings or { });
      children = lib.filterAttrs (_: hasSettingsDeep) (childNodes node);
    in
    {
      imports = own.imports or [ ];
      config = own.config or { };
      options =
        (own.options or { })
        // lib.mapAttrs (
          name: child:
          mkOption {
            type = types.submodule (nodeModule child);
            default = { };
            description = "Settings under ${name}";
          }
        ) children;
    };
in
types.submodule (nodeModule (den.ful.fleet or { }))
