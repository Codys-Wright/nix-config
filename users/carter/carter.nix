{ FTS, den, ... }:
{
  # Darwin (macOS) home configuration
  den.homes.aarch64-darwin.carter = {
    userName = "electric";
    aspect = "carter";
  };

  # NixOS home configuration
  den.homes.x86_64-linux.carter = {
    userName = "carter";
    aspect = "carter";
  };

  # Carter user aspect - includes user-specific configurations
  # This is evaluated when the carter user is on a host
  # Note: den auto-generates a parametric aspect for users, so we merge into it
  den.aspects.carter = {
    description = "Carter user configuration";
    includes = [
      # Home-manager backup system
      den.aspects.hm-backup
      
      # Install all terminals with ghostty as default
      # (FTS.coding._.terminals { default = "ghostty"; })
      FTS.coding
      # FTS.yazi
      # FTS.fzf
    ];

    # NixOS-level configuration for carter
    nixos = { pkgs, ... }: {
    };

    # Home Manager configuration for carter
    homeManager = { 
    };
  };

  # aspect for each host that includes the user carter.
  den.aspects.carter.provides.hostUser =
        { user, ... }:
        {
          # administrator in all nixos hosts
          nixos.users.users.${user.userName} = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
          # darwin configuration
          darwin.system.primaryUser = user.userName;
        };

      # Password configuration for carter
  den.aspects.carter.provides.password =
        { user, ... }:
        {
          nixos.users.users.${user.userName} = {
            initialPassword = "password"; # TODO: Change this to a hashed password in production
          };
        };

      # Autologin configuration for carter (useful for VM testing)
  den.aspects.carter.provides.autologin =
        { user, ... }:
        {
          nixos =
            { config, lib, ... }:
            lib.mkIf config.services.displayManager.enable {
              services.displayManager.autoLogin = {
                enable = true;
                user = user.userName;
            };
        };
  };

}
