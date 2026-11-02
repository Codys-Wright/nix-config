# Teley, always on (STA-642): the worker on 127.0.0.1:8787 and the OTLP
# collector on 127.0.0.1:4318 in front of it, so every app's
# OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318 and Cody's
# `teley-cli mcp --host localhost:8787` find a stack without a `devenv up`.
# Built from devenv-fleet (pkgs/teley.nix); the room is ~/.teley/session.json.
#
#   Linux:  a home-manager user service pair; included by cody@THEBATTLESHIP.
#   macOS:  (<fleet.coding.cli/teley-launchd> { user = "rat"; }) a LaunchDaemon run as
#           that user, since airlock's rat has no home-manager.
#
# A dev shell's `devenv up` (devenv-fleet/telemetry) probes the ports and
# attaches to this stack instead of starting a second one.
{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.devenv-fleet = {
    url = lib.mkDefault "github:FastTrackStudios/devenv-fleet/v0.1.0";
    # Only its pkgs/ are used; the pins flake would add a second nixpkgs lock.
    flake = false;
  };

  fleet.coding._.cli._.teley = {
    description = "Teley worker (:8787) and OTLP collector (:4318) as always-on user services (Linux home-manager)";

    homeManager =
      { pkgs, ... }:
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
        let
          teley = import ./_teley/service.nix {
            inherit pkgs;
            devenvFleet = inputs.devenv-fleet;
          };
        in
        {
          systemd.user.services.teley = {
            Unit.Description = "Teley worker (wrangler dev) on 127.0.0.1:${toString teley.teleyPort}";
            Service = {
              ExecStart = lib.getExe' teley.worker "teley-worker";
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install.WantedBy = [ "default.target" ];
          };

          systemd.user.services.teley-collector = {
            Unit = {
              Description = "OTLP collector on 127.0.0.1:4318, forwarding to Teley's room";
              After = [ "teley.service" ];
              Wants = [ "teley.service" ];
            };
            Service = {
              ExecStart = lib.getExe teley.collector;
              Restart = "on-failure";
              RestartSec = 5;
            };
            Install.WantedBy = [ "default.target" ];
          };
        }
      );
  };

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
