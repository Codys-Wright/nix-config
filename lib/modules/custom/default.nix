{ lib, ... }: with lib; rec {
  # use path relative to the root of the project
  relativeToRoot = path.append ../.;

  # use path relative to modules/common/optional (where most modules will live)
  relativeToOptionalModules =
    subPath:
    path.append ../. "modules/common/optional${if subPath != "" then "/${subPath}" else ""}";

  # use path relative to modules/hosts/nixos (for NixOS-specific modules)
  relativeToNixOsModules =
    subPath: path.append ../. "modules/hosts/nixos${if subPath != "" then "/${subPath}" else ""}";

  # use path relative to modules/nixos (for NixOS modules)
  relativeToNixOsModulesNew =
    subPath: path.append ../. "modules/nixos${if subPath != "" then "/${subPath}" else ""}";

  # use path relative to modules/home (for Home Manager modules)
  relativeToHomeModules =
    subPath: path.append ../. "modules/home${if subPath != "" then "/${subPath}" else ""}";

  # use path relative to systems (for system configurations)
  relativeToSystems =
    subPath: path.append ../. "systems${if subPath != "" then "/${subPath}" else ""}";

  # use path relative to homes (for home configurations)
  relativeToHomes =
    subPath: path.append ../. "homes${if subPath != "" then "/${subPath}" else ""}";

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
}