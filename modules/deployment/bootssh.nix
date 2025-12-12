# Boot SSH module
# Enables SSH access during initrd boot for remote unlocking
# Automatically enables if host keys are found
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.deployment._.bootssh = {
    description = ''
      SSH access during initrd boot for remote system unlocking.
      
      Automatically enables if host keys exist at hosts/<hostname>/initrd_ssh_host_key
      Automatically uses deployment.sshKey from deployment.config.
      
      Usage:
        <FTS.deployment/bootssh>  # Auto-detects host keys
        (<FTS.deployment/bootssh> { sshPort = 2223; })  # Custom port
        (<FTS.deployment/bootssh> { hostKeys = [ ./my-key ]; })  # Custom keys
    '';

    __functor =
      _self:
      {
        enable ? null,  # null = auto-detect, true = force enable, false = disable
        sshPort ? 2223,
        hostKeys ? null,  # null = auto-detect from hosts/<hostname>/initrd_ssh_host_key
        authorizedKeys ? null,  # null = use deployment.sshKey
        staticNetwork ? null,  # null = use deployment.staticNetwork
        ...
      }@args:
      { class, aspect-chain }:
      {
        nixos = { config, pkgs, lib, ... }:
        let
          cfg = config.deployment;
          hostname = config.networking.hostName or "nixos";
          
          # Auto-detect host keys
          defaultHostKeyPath = ../../hosts/${hostname}/initrd_ssh_host_key;
          hostKeyExists = builtins.tryEval (builtins.pathExists defaultHostKeyPath);
          hasHostKey = hostKeyExists.success && hostKeyExists.value;
          
          # Determine if we should enable
          shouldEnable = 
            if enable != null then enable  # Explicit override
            else if hostKeys != null then true  # If hostKeys provided, enable
            else hasHostKey;  # Auto-detect based on file existence
          
          # Determine which host keys to use
          actualHostKeys = 
            if hostKeys != null then hostKeys
            else if hasHostKey then [ defaultHostKeyPath ]
            else [];
          
          # Determine authorized keys
          actualAuthorizedKeys =
            if authorizedKeys != null then authorizedKeys
            else if cfg.sshKey != null then [ cfg.sshKey ]
            else [];
          
          # Determine network config
          actualStaticNetwork = if staticNetwork != null then staticNetwork else cfg.staticNetwork;
        in
        lib.mkIf (cfg.enable && shouldEnable) {
          # Enable DHCP in stage-1 (or use static network)
          boot.initrd.network.udhcpc.enable = lib.mkDefault (actualStaticNetwork == null);

          # Enable SSH during initrd boot
          boot.initrd.network = {
            enable = true;
            ssh = {
              enable = true;
              port = sshPort;
              hostKeys = actualHostKeys;
              authorizedKeys = actualAuthorizedKeys;
            };
          };

          # Static IP for initrd if configured
          boot.kernelParams = lib.optionals (actualStaticNetwork != null) [
            "ip=${actualStaticNetwork.ip}::${actualStaticNetwork.gateway}:255.255.255.0:${hostname}-initrd:${actualStaticNetwork.device}:off:::"
          ];
        };
      };
  };
}
