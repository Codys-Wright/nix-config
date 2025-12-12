# SSH server configuration
{
  FTS,
  ...
}:
{
  FTS.system._.ssh = {
    description = "SSH server configuration with secure defaults";

    nixos = { config, lib, pkgs, ... }: {
      services.openssh = {
        enable = lib.mkDefault true;
        settings = {
          PermitRootLogin = lib.mkDefault "prohibit-password";
          PasswordAuthentication = lib.mkDefault true;
        };
        ports = [ 22 ];
      };
    };
  };
}

