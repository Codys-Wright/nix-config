# Deployment default aspect
# Includes all deployment aspects for easy inclusion
{
  inputs,
  den,
  lib,
  deployment,
  ...
}:
{
  deployment.default = {
    description = "Default deployment configuration (includes all deployment aspects)";
    
    # Include all deployment aspects
    includes = [
      deployment.config  
      # deployment.bootssh  # Temporarily disabled - requires /boot/host_key
      deployment.hotspot
      # deployment.beacon  # Temporarily disabled - requires isoImage which isn't available in regular NixOS configs
    ];
  };
}

