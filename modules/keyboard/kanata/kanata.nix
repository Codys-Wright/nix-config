{ inputs, lib, den, ... }:

{
  den.aspects.kanata = {
    description = "Kanata keyboard remapper for both NixOS and Darwin";

    nixos = { config, pkgs, lib, ... }:
    let
      cfg = config.den.aspects.kanata;
      inherit (lib) mkIf mkEnableOption mkOption types;
    in
    {
      options.den.aspects.kanata = {
        enable = mkEnableOption "Kanata keyboard remapper";

        package = mkOption {
          type = types.package;
          default = pkgs.kanata;
          description = "Kanata package to use";
        };

        configFile = mkOption {
          type = types.path;
          default = ./kanata.kbd;
          description = "Path to the Kanata configuration file";
        };

        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra arguments to pass to Kanata";
        };

        devices = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Specific devices to target (empty means all devices)";
        };

        port = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Port number for Kanata daemon";
        };
      };

      config = mkIf cfg.enable {
        services.kanata = {
          enable = true;
          package = cfg.package;
          keyboards.fts-kanata = {
            configFile = cfg.configFile;
            extraArgs = cfg.extraArgs;
            devices = cfg.devices;
            port = cfg.port;
            extraDefCfg = "process-unmapped-keys yes";
          };
        };

        # Add the Kanata service user to necessary groups for input devices
        systemd.services.kanata-fts-kanata.serviceConfig = {
          SupplementaryGroups = [
            "input"
            "uinput"
          ];
        };
      };
    };

    darwin = { config, pkgs, lib, ... }:
    let
      cfg = config.den.aspects.kanata;
      inherit (lib) mkIf mkEnableOption mkOption types;
    in
    {
      options.den.aspects.kanata = {
        enable = mkEnableOption "Kanata keyboard remapper";

        package = mkOption {
          type = types.package;
          default = pkgs.kanata;
          description = "Kanata package to use";
        };

        configFile = mkOption {
          type = types.path;
          default = ./kanata.kbd;
          description = "Path to the Kanata configuration file";
        };

        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra arguments to pass to Kanata";
        };

        devices = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Specific devices to target (empty means all devices)";
        };

        port = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Port number for Kanata daemon";
        };
      };

      config = mkIf cfg.enable {
        # Install Kanata package
        environment.systemPackages = [ cfg.package ];

        # Create launchd service for Kanata on Darwin
        launchd.user.agents.kanata = {
          serviceConfig = {
            ProgramArguments = [
              "${cfg.package}/bin/kanata"
              "--cfg" "${cfg.configFile}"
            ] ++ lib.optionals (cfg.devices != []) (lib.flatten (map (d: ["--device" d]) cfg.devices))
              ++ lib.optionals (cfg.port != null) ["--port" (toString cfg.port)]
              ++ cfg.extraArgs;

            RunAtLoad = true;
            KeepAlive = true;

            StandardOutPath = "/tmp/kanata.log";
            StandardErrorPath = "/tmp/kanata.log";
          };
        };

        # Grant necessary permissions for input access on macOS
        # Note: Users may need to grant Accessibility permissions manually
        # in System Preferences > Security & Privacy > Privacy > Accessibility
      };
    };
  };
}
