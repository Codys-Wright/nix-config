# Teley, always on (STA-642): the worker on 127.0.0.1:8787 and the OTLP
# collector on 127.0.0.1:4318 in front of it, so every app's
# OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 and Cody's
# `teley-cli mcp --host localhost:8787` find a stack without a `devenv up`.
# Built from devenv-fleet (pkgs/teley.nix, the input is declared in
# telemetry.nix); the room is ~/.teley/session.json.
#
#   macOS:  (<fleet.coding.cli/teley-launchd> { user = "rat"; }) a LaunchDaemon run as
#           that user, since airlock's rat has no home-manager.
#
# Linux (THEBATTLESHIP) runs OpenObserve and its collector instead: telemetry.nix.
#
# A dev shell's `devenv up` (devenv-fleet/telemetry) probes the ports and
# attaches to this stack instead of starting a second one.
{
  inputs,
  lib,
  ...
}:
{
  fleet.coding._.cli._.teley-launchd.__functor =
    _self:
    {
      # The macOS account whose ~/.teley/session.json is the room.
      user,
      home ? "/Users/${user}",
      ...
    }:
    {
      name = "teley-launchd(${user})";
      description = "Teley worker and OTLP collector as boot-time LaunchDaemons run as ${user}";
      darwin =
        { pkgs, ... }:
        let
          teley = import ./_teley/service.nix {
            inherit pkgs;
            devenvFleet = inputs.devenv-fleet;
          };
          daemon = program: {
            serviceConfig = {
              ProgramArguments = [ program ];
              UserName = user;
              KeepAlive = true;
              ThrottleInterval = 10;
              EnvironmentVariables.HOME = home;
              StandardErrorPath = "${home}/Library/Logs/teley.log";
              StandardOutPath = "${home}/Library/Logs/teley.log";
            };
          };
        in
        {
          launchd.daemons.teley = daemon (lib.getExe' teley.worker "teley-worker");
          launchd.daemons.teley-collector = daemon (lib.getExe teley.collector);
        };
    };
}
