# Deployment base configuration
# Provides essential deployment settings that other deployment modules can use
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.deployment._.config = {
    description = ''
      Base deployment configuration for remote NixOS hosts.
      
      Provides SSH access, networking, user setup, and system hardening.
      Other deployment modules (bootssh, hotspot, secrets) can access these settings.
    '';

    nixos = { config, pkgs, lib, ... }:
    let
      hostname = config.networking.hostName or "nixos";
      
      # Auto-derive SSH key
      defaultSshKeyPath = ../../hosts/${hostname}/ssh.pub;
      sshKeyPathExists = builtins.tryEval (builtins.pathExists defaultSshKeyPath);
      sshKey = if sshKeyPathExists.success && sshKeyPathExists.value 
               then lib.strings.trim (builtins.readFile defaultSshKeyPath)
               else null;
    in
    {
      # These options are available for other deployment modules to use
      options.deployment = {
        enable = lib.mkEnableOption "deployment configuration" // { default = true; };
        
        # Network configuration
        staticNetwork = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              ip = lib.mkOption { type = lib.types.str; };
              gateway = lib.mkOption { type = lib.types.str; };
              device = lib.mkOption { type = lib.types.str; default = "en*"; };
            };
          });
          default = null;
          description = "Static network configuration (null = DHCP)";
        };
        
        # User configuration  
        username = lib.mkOption {
          type = lib.types.str;
          default = "admin";
          description = "Admin username";
        };
        
        sshKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = sshKey;
          description = "SSH public key for access";
        };
      };

      config = lib.mkIf config.deployment.enable {
        # Networking (DHCP by default, static if configured)
        systemd.network = 
          if config.deployment.staticNetwork == null then {
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
              address = [ "${config.deployment.staticNetwork.ip}/24" ];
              routes = [ { Gateway = config.deployment.staticNetwork.gateway; } ];
              linkConfig.RequiredForOnline = true;
            };
          };

        # System optimization
        powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
        
        nix.settings.trusted-users = [ config.deployment.username ];
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.settings.auto-optimise-store = true;
        nix.gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          options = lib.mkDefault "--delete-older-than 30d";
        };

        services.journald.extraConfig = lib.mkDefault ''
          SystemMaxUse=2G
          SystemKeepFree=4G
          SystemMaxFileSize=100M
          MaxFileSec=day
        '';

        # User setup
        users.mutableUsers = lib.mkDefault false;
        users.users.${config.deployment.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = lib.mkIf (config.deployment.sshKey != null) [ config.deployment.sshKey ];
        };

        # Sudo without password
        security.sudo.extraRules = [
          {
            users = [ config.deployment.username ];
            commands = [{
              command = "ALL";
              options = [ "NOPASSWD" ];
            }];
          }
        ];

        # SSH server configuration
        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = lib.mkForce "no";
            PasswordAuthentication = lib.mkForce false;
          };
          ports = [ 22 ];
        };

        # Essential deployment packages
        environment.systemPackages = with pkgs; [
          vim
          curl
          nixos-facter
        ];
      };
    };
  };
}
