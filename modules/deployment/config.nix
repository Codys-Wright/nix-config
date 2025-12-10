# Deployment configuration module
# Provides config.deployment options for hosts to configure deployment settings
{
  inputs,
  den,
  lib,
  deployment,
  ...
}:
let
  inherit (lib) isString mkOption toInt types;
  readAndTrim = f: lib.strings.trim (builtins.readFile f);
  readAsStr = v: if lib.isPath v then readAndTrim v else v;
  readAsInt = v: let
    vStr = readAsStr v;
  in
    if isString vStr then toInt vStr else vStr;
in
{
  deployment.config = {
    description = "Deployment configuration for remote NixOS hosts";

    nixos = { config, pkgs, lib, ... }:
    let
      inherit (lib) isString mkOption toInt types;
      cfg = config.deployment;
      readAndTrim = f: lib.strings.trim (builtins.readFile f);
      readAsStr = v: if lib.isPath v then readAndTrim v else v;
      
      # Auto-derive hostname from config (set by den)
      hostname = config.networking.hostName or "nixos";
      
      # Hardcoded paths following convention: hosts/<hostname>/
      # Paths are constructed relative to flake root
      secretsYamlPath = ../../hosts/${hostname}/secrets.yaml;
      
      # Try to get first user from host context, fallback to "admin"
      firstUserName = let
        host = config._module.args.host or null;
        users = if host != null then (builtins.attrNames (host.users or {})) else [];
      in
        if users != [] then builtins.head users else "admin";
      
      # SSH key is now stored in SOPS, referenced via sops.secrets
      # Public keys and known_hosts are still files
      hostKeyPub = "./hosts/${hostname}/host_key.pub";
      knownHostsPath = "./hosts/${hostname}/known_hosts";
      # Path to facter.json (relative to host file, so ./facter.json from host directory)
      facterConfigPath = ./facter.json;
    in
    {
      # Always import SOPS module
      imports = [
        inputs.sops-nix.nixosModules.default
      ];

      options.deployment = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;  # Enabled by default when aspect is included
          description = "Enable deployment configuration for this host";
        };

        # Connection/deployment options
        ip = lib.mkOption {
          type = lib.types.str;
          description = "IP address or hostname to connect to this host";
          example = "192.168.1.10";
        };

        sshPort = lib.mkOption {
          type = lib.types.port;
          default = 22;
          description = "SSH port to connect to this host (default: 22)";
        };

        sshUser = lib.mkOption {
          type = lib.types.str;
          default = firstUserName;
          defaultText = "first user from host.users or 'root'";
          description = "SSH user to connect as (defaults to first user from host.users, or 'root')";
        };

        # System configuration options
        username = mkOption {
          description = "Name given to the admin user on the server";
          type = types.str;
          default = firstUserName;
          defaultText = "first user from host.users or 'admin'";
        };

        staticNetwork = mkOption {
          description = "Use static IP configuration. If unset, use DHCP";
          default = null;
          example = lib.literalExpression ''
            {
              ip = "192.168.1.30";
              gateway = "192.168.1.1";
            }
          '';
          type = types.nullOr (types.submodule {
            options = {
              enable = lib.mkEnableOption "Static IP configuration";

              ip = mkOption {
                type = types.str;
                description = "Static IP to use";
              };

              gateway = mkOption {
                type = types.str;
                description = "IP Gateway, often same beginning as `ip` and finishing by a `1`: `XXX.YYY.ZZZ.1`";
              };

              device = mkOption {
                description = ''
                  Device for which to configure the IP address for.

                  Either pass the device name directly if you know it, like "ens3".
                  Or configure the `deviceName` option to get the first device name
                  matching that prefix from the facter.json report.
                '';
                default = { namePrefix = "en"; };
                type = with types; oneOf [
                  str
                  (submodule {
                    options = {
                      namePrefix = mkOption {
                        type = str;
                        description = "Name prefix as it appears in the facter.json report. Used to distinguish between wifi and ethernet";
                        default = "en";
                        example = "wl";
                      };
                    };
                  })
                ];
              };

              deviceName = mkOption {
                description = ''
                  Result of applying match pattern from `.device` option
                  or the string defined in `.device` option.
                '';
                readOnly = true;
                internal = true;
                default = let
                  cfg' = cfg.staticNetwork;
                  network_interfaces = config.facter.report.hardware.network_interface or [];
                  firstMatchingDevice = builtins.head (builtins.filter (lib.hasPrefix (if isString cfg'.device then "" else cfg'.device.namePrefix)) (lib.flatten (map (x: x.unix_device_names or []) network_interfaces)));
                in
                  if isString cfg'.device then cfg'.device else firstMatchingDevice;
              };
            };
          });
        };

        disableNetworkSetup = mkOption {
          description = ''
            If set to true, completely disable network setup by deployment module.

            Make sure you can still ssh to the server.
          '';
          type = types.bool;
          default = false;
        };

        password = mkOption {
          description = "Plain password for the admin user (will be hashed in NixOS). Auto-derives from SOPS secrets at ${hostname}/system/user/password if available, otherwise can be a string or path.";
          type = lib.types.nullOr (lib.types.oneOf [ types.str types.path ]);
          # Auto-derive from SOPS if available, otherwise null
          default = let
            sopsSecretPath = "${hostname}/system/user/password";
            sopsSecrets = config.sops.secrets or {};
            sopsSecret = sopsSecrets.${sopsSecretPath} or null;
          in
            if sopsSecret != null && sopsSecret ? path then sopsSecret.path else null;
          defaultText = ''config.sops.secrets."${hostname}/system/user/password".path if SOPS is configured, else null'';
          apply = v: if v == null then null else (if lib.isPath v then readAndTrim v else v);
        };


        hostId = mkOption {
          type = types.nullOr types.str;
          description = "8 characters unique identifier for this server. Generate with `uuidgen | head -c 8`";
          default = null;
        };

        sshAuthorizedKey = mkOption {
          type = with types; nullOr (oneOf [ str path ]);
          description = "Public SSH key used to connect on boot. Auto-derives from ./hosts/<hostname>/ssh.pub if available.";
          # Auto-derive from hardcoded path if file exists
          default = let
            sshKeyPath = ../../hosts/${hostname}/ssh.pub;
            pathExists = builtins.tryEval (builtins.pathExists sshKeyPath);
          in
            if pathExists.success then sshKeyPath else null;
          defaultText = ''"./hosts/${hostname}/ssh.pub" if exists, else null'';
          apply = v: if v == null then null else readAsStr v;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.staticNetwork == null -> (config.boot.initrd.network.udhcpc.enable or false);
            message = ''
              If DHCP is disabled and an IP is not set, the box will not be reachable through the network on boot.

              To fix this error, either set config.boot.initrd.network.udhcpc.enable = true or give an IP to deployment.staticNetwork.ip.
            '';
          }
        ];

        # Automatically configure SOPS
        sops.defaultSopsFile = secretsYamlPath;
        
        # Auto-configure SOPS secret for SSH private key (stored in SOPS, decrypted to /run/secrets)
        # The key should be stored in secrets.yaml at: <hostname>.system.sshPrivateKey
        sops.secrets."${hostname}/system/sshPrivateKey" = {
          format = "binary";  # SSH keys are binary
          mode = "0600";  # Private key permissions
          # Path defaults to /run/secrets/<hostname>/system/sshPrivateKey
        };

        # Auto-configure boot SSH authorized keys from deployment.sshAuthorizedKey
        # This allows remote unlocking during initrd boot
        deployment.boot.authorizedKeys = lib.mkIf (cfg.sshAuthorizedKey != null) [
          (if lib.isPath cfg.sshAuthorizedKey then readAndTrim cfg.sshAuthorizedKey else cfg.sshAuthorizedKey)
        ];

        # Use facter.json from hosts/<hostname>/facter.json if it exists
        # Only set if the file exists (allows building before hardware is detected)
        # Note: Path is resolved relative to the host file location
        facter.reportPath = lib.mkIf (builtins.pathExists facterConfigPath) facterConfigPath;

        networking.hostId = lib.mkIf (cfg.hostId != null) cfg.hostId;

        systemd.network = lib.mkIf (!cfg.disableNetworkSetup) (
          if cfg.staticNetwork == null then {
            enable = true;
            networks."10-lan" = {
              matchConfig.Name = "en*";
              networkConfig.DHCP = "ipv4";
              linkConfig.RequiredForOnline = true;
            };
          } else {
            enable = true;
            networks."10-lan" = {
              matchConfig.Name = "en*";
              address = [
                "${cfg.staticNetwork.ip}/24"
              ];
              routes = [
                { Gateway = cfg.staticNetwork.gateway; }
              ];
              linkConfig.RequiredForOnline = true;
            };
          });

        powerManagement.cpuFreqGovernor = "performance";

        nix.settings.trusted-users = [ cfg.username ];
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.settings.auto-optimise-store = true;
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };

        services.journald.extraConfig = ''
          SystemMaxUse=2G
          SystemKeepFree=4G
          SystemMaxFileSize=100M
          MaxFileSec=day
        '';

        users.mutableUsers = false;
        users.users.${cfg.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          # Hash the password in NixOS if provided (from SOPS)
          # Uses mkpasswd to hash the plain password at evaluation time
          hashedPassword = lib.mkIf (cfg.password != null) (
            lib.strings.removeSuffix "\n" (
              builtins.readFile (
                pkgs.runCommand "hash-password"
                  { buildInputs = [ pkgs.mkpasswd ]; }
                  ''
                    mkpasswd -m sha-512 "${lib.escapeShellArg cfg.password}" > $out
                  ''
              )
            )
          );
          openssh.authorizedKeys.keys = lib.mkIf (cfg.sshAuthorizedKey != null) [ cfg.sshAuthorizedKey ];
        };

        security.sudo.extraRules = [
          {
            users = [ cfg.username ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        environment.systemPackages = [
          pkgs.vim
          pkgs.curl
          pkgs.nixos-facter
        ];

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          };
          ports = [ cfg.sshPort ];
        };
      };
    };
  };
}

