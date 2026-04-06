# Simple deploy-rs target aspect
# Defines NixOS options that deploy-rs.nix auto-discovers.
# Any host that includes this becomes deployable via `just deploy <host>`.
#
# Usage:
#   (fleet.deploy { ip = "100.74.250.99"; })
#   (fleet.deploy { ip = "192.168.0.106"; sshUser = "root"; })
#   (fleet.deploy { ip = "10.0.0.1"; sshPort = 2222; })
{
  fleet,
  lib,
  ...
}:
{
  fleet.deploy = {
    description = "Deploy-rs target: makes a host remotely deployable via `just deploy <host>`";

    __functor =
      _self:
      {
        ip,
        sshPort ? 22,
        sshUser ? "root",
        ...
      }:
      {
        nixos =
          { lib, ... }:
          {
            options.deployment = {
              enable = lib.mkEnableOption "deploy-rs deployment" // {
                default = true;
              };
              ip = lib.mkOption {
                type = lib.types.str;
                default = ip;
                description = "IP address for deploy-rs to target";
              };
              sshPort = lib.mkOption {
                type = lib.types.port;
                default = sshPort;
                description = "SSH port for deploy-rs";
              };
              sshUser = lib.mkOption {
                type = lib.types.str;
                default = sshUser;
                description = "SSH user for deploy-rs";
              };
            };
          };
      };
  };
}
