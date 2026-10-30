# SSH server configuration
{ fleet, ssh-keys, ... }:
{
  fleet.system._.ssh = {
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

        # deploy-rs remote builds talk ssh-ng: the `nix-daemon --stdio` it starts
        # inherits the SSH session's open-file limit (soft 1024), which a
        # parallel remote build exhausts ("Too many open files").
        systemd.services.sshd.serviceConfig.LimitNOFILE = 1048576;

        # Allow all fleet machines to SSH into root
        users.users.root.openssh.authorizedKeys.keys = ssh-keys.all;
      };
  };

}
