# System user configuration aspect
# Works with den's user context system to configure users on hosts
{
  FTS,
  lib,
  ...
}:
let
  description = ''
    System user configuration that works with den's user context system.

    This aspect automatically configures users based on the den host user definitions.
    It sets up proper user accounts with appropriate groups and permissions.

    Works automatically when users are defined in den.hosts.*.users.* = { };

    Example:
      den.hosts.x86_64-linux.myhost.users.alice = { };
      # This aspect will automatically configure user 'alice' when included
  '';

  # Configure user based on den user context
  userContext =
    { user, host, ... }:
    let
      homeDir =
        if lib.hasSuffix "darwin" host.system then "/Users/${user.userName}" else "/home/${user.userName}";
    in
    {
      # Basic user setup for NixOS
      nixos.users.users.${user.userName} = {
        isNormalUser = true;
        inherit (user) extraGroups;
        home = homeDir;
        createHome = true;
      };

      # Darwin user setup (if on macOS)
      darwin.users.users.${user.userName} = lib.mkIf (lib.hasSuffix "darwin" host.system) {
        name = user.userName;
        home = homeDir;
      };
    };

  # Fallback user creation when no users are defined
  defaultUserContext =
    { host, ... }:
    lib.mkIf (host.users or { } == { }) {
      nixos.users.users.nixos = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        initialPassword = "nixos";
        description = "Default NixOS user";
      };
    };
in
{
  FTS.user._.base = {
    inherit description;
    includes = [
      userContext
      defaultUserContext
    ];
  };
}
