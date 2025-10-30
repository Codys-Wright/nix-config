# example aspect dependencies for our hosts
# Feel free to remove it, adapt or split into modules.
# see also: defaults.nix, compat-imports.nix, home-managed.nix
{
  inputs,
  den,
  lib,
  ...
}:
{
  # see also defaults.nix where static settings are set.
  den.default = {
    # parametric defaults for host/user/home. see aspects/dependencies.nix
    # `_` is shorthand alias for `provides`.
    host.includes = [
      den.aspects.example._.host
      den.aspects.nh
    ];
    user.includes = [ den.aspects.example._.user ];
    home.includes = [
      den.aspects.example._.home
      # Include coding aspects for all homes
      den.aspects.cli-tools
      den.aspects.shell-tools
      # Include language support
      den.aspects.rust
      den.aspects.typescript
      # Include development tools
      den.aspects.git
      den.aspects.docker
      den.aspects.lazygit
      den.aspects.opencode
      den.aspects.dev-tools
    ];
    
  };

  # aspects for our example host/user/home definitions.
  # on a real setup you will split these over into multiple dendritic files.
  den.aspects = {
  
    developer = {
      description = "aspect for bob's standalone home-manager";
      homeManager = { };
    };
    # adding a parametric aspect on a specific host/user/home.
    developer._.home.includes = [ den.aspects.example._.home ];


   
    # subtree of aspects for demo purposes.
    example.provides = {

      # in our example, we allow all nixos hosts to be vm-bootable.
      vm-bootable = {
        nixos =
          { modulesPath, ... }:
          {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
          };
      };

      # parametric providers.
      host =
        { host }:
        { class, ... }:
        {
          # `_` is a shorthand alias for `provides`
          includes = [ den.aspects.example._.vm-bootable ];
          ${class}.networking.hostName = host.hostName;
        };

      user =
        { user, host }:
        let
          by-class.nixos.users.users.${user.userName}.isNormalUser = true;
          by-class.darwin = {
            system.primaryUser = user.userName;
            users.users.${user.userName}.isNormalUser = true;
          };

          # adelie is nixos-on-wsl, has special additional user setup
          by-host.outrider.nixos.defaultUser = user.userName;
        in
        {
          includes = [
            by-class
            (by-host.${host.name} or { })
          ];
        };

      home =
        { home }:
        { class, ... }:
        let
          homeDir = if lib.hasSuffix "darwin" home.system then "/Users" else "/home";
        in
        {
          ${class}.home = {
            username = lib.mkDefault home.userName;
            homeDirectory = lib.mkDefault "${homeDir}/${home.userName}";
          };
        };

    };

  };
}
