# Auto-discover microvm hosts and expose their runners as packages
# Any host with microvm.declaredRunner gets a `nix run .#<hostname>` package
{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { system, ... }:
    let
      nixosConfigs = inputs.self.nixosConfigurations or { };
      microvmHosts = lib.filterAttrs (
        _name: cfg:
        let
          tryRunner = builtins.tryEval (cfg.config.microvm.declaredRunner or null);
        in
        tryRunner.success && tryRunner.value != null
      ) nixosConfigs;
    in
    lib.optionalAttrs (system == "x86_64-linux") {
      packages = lib.mapAttrs (_name: cfg: cfg.config.microvm.declaredRunner) microvmHosts;
    };
}
