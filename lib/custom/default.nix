{
    # This is the merged library containing your namespaced library as well as all libraries from
    # your flake's inputs.
    lib,

    # Your flake inputs are also available.
    inputs,

    # The namespace used for your flake, defaulting to "internal" if not set.
    namespace,

    # Additionally, Snowfall Lib's own inputs are passed. You probably don't need to use this!
    snowfall-inputs,
}:
{
    # use path relative to the root of the project
    relativeToRoot = lib.path.append ../.;

    # use path relative to modules/common/optional (where most modules will live)
    relativeToOptionalModules =
      subPath:
      lib.path.append ../. "modules/common/optional${if subPath != "" then "/${subPath}" else ""}";

    # use path relative to modules/hosts/nixos (for NixOS-specific modules)
    relativeToNixOsModules =
      subPath: lib.path.append ../. "modules/hosts/nixos${if subPath != "" then "/${subPath}" else ""}";

    # use path relative to modules/nixos (for NixOS modules)
    relativeToNixOsModulesNew =
      subPath: lib.path.append ../. "modules/nixos${if subPath != "" then "/${subPath}" else ""}";

    # use path relative to modules/home (for Home Manager modules)
    relativeToHomeModules =
      subPath: lib.path.append ../. "modules/home${if subPath != "" then "/${subPath}" else ""}";

    # use path relative to systems (for system configurations)
    relativeToSystems =
      subPath: lib.path.append ../. "systems${if subPath != "" then "/${subPath}" else ""}";

    # use path relative to homes (for home configurations)
    relativeToHomes =
      subPath: lib.path.append ../. "homes${if subPath != "" then "/${subPath}" else ""}";

    # Helper to create a unified module more easily
    # Usage: lib.custom.mkUnifiedModule { systemConfig = {...}; userConfig = {...}; }
    mkUnifiedModule =
      {
        systemConfig ? { },
        userConfig ? { },
      }:
      {
        inherit systemConfig userConfig;
      };

  randomBackupExt = inputs: "backup_${toString (builtins.hashString "sha256" (toString inputs.nixpkgs))}";
}