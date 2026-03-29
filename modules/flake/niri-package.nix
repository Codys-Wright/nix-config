# Standalone niri package with the full desktop config embedded.
# Run with: nix run .#niri
#
# Extracts the homeManager module from FTS.desktop.environment.niri,
# evaluates it with home-manager standalone, pulls out the generated
# config.kdl, and wraps the niri binary with it.
#
# This lets you test the niri config without a VM — just run `nix run .#niri`
# and niri opens as a nested window inside your existing compositor.
{
  inputs,
  FTS,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.niri =
        let
          # Pull the homeManager block directly from the niri aspect.
          # The aspect is self-contained (no sub-includes with homeManager content)
          # so we don't need den.lib.aspects.resolve here.
          niriHmModule = FTS.desktop._.environment._.niri.homeManager;

          # Evaluate home-manager standalone with the niri aspect.
          # home-manager provides xdg, fonts, and all other HM infrastructure.
          hmConfig = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              niriHmModule
              {
                home.username = "user";
                home.homeDirectory = "/home/user";
                home.stateVersion = "25.11";
              }
            ];
          };

          # niri-flake writes the validated config.kdl to xdg.configFile."niri-config"
          configKdl = hmConfig.config.xdg.configFile."niri-config".source;

          # Use niri-stable from the niri-flake input (same version as the system config)
          niriPkg = inputs.niri-flake.packages.${system}.niri-stable;
        in
        pkgs.writeShellScriptBin "niri" ''
          exec ${niriPkg}/bin/niri -c ${configKdl} "$@"
        '';
    };
}
