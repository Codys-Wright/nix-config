{ lib
, config
, pkgs
, namespace
, ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.snowfall-flake;
in
{
  options.${namespace}.programs.snowfall-flake = with types; {
    enable = mkBoolOpt false ''
      Whether to enable the Snowfall Flake tool for easier Nix Flake development.

      This installs the snowfallorg.flake package which provides convenient commands
      for working with Nix Flakes:
      - flake new - Create new projects from templates
      - flake init - Initialize flakes in existing projects  
      - flake dev - Run development shells
      - flake run - Run apps from flakes
      - flake build - Build packages from flakes
      - flake switch - Switch system configurations
      - flake update - Update flake inputs
      - flake show - Show flake outputs

      Example:
      ```nix
      FTS-FLEET = {
        programs.snowfall-flake = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      snowfallorg.flake
    ];
  };
}
