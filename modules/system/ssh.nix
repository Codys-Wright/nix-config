# SSH server configuration
{ FTS, ssh-keys, ... }:
{
  FTS.system._.ssh = {
    description = "SSH server configuration with secure defaults and fleet access";

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        services.openssh = {
          enable = lib.mkDefault true;
          settings = {
            PermitRootLogin = lib.mkOverride 1500 "prohibit-password";
            PasswordAuthentication = lib.mkDefault true;
          };
          ports = [ 22 ];
        };

        # Allow all fleet machines to SSH into root
        users.users.root.openssh.authorizedKeys.keys = ssh-keys.all;
      };
  };

}
