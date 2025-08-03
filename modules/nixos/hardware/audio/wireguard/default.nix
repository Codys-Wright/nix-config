{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.audio.wireguard;
in
{
  options.${namespace}.hardware.audio.wireguard = with types; {
    enable = mkBoolOpt false "Enable WireGuard audio device management";
    systemOutput = mkOpt (nullOr str) null "System output device name (optional)";
    dawOutput = mkOpt (nullOr str) null "DAW output device name (optional)";
    defaultInput = mkOpt (nullOr str) null "Default input device name (optional)";
  };

  config = mkIf cfg.enable {
    # WirePlumber configuration for device management
    services.pipewire.wireplumber.extraConfig.main."50-device-preferences" = ''
      -- WireGuard Audio Device Preferences
      -- Set default devices for different audio contexts
      
      -- Default device preferences (only set if provided)
      local system_output = ${if cfg.systemOutput != null then "\"${cfg.systemOutput}\"" else "nil"}
      local daw_output = ${if cfg.dawOutput != null then "\"${cfg.dawOutput}\"" else "nil"}
      local default_input = ${if cfg.defaultInput != null then "\"${cfg.defaultInput}\"" else "nil"}
      
      -- Rules for setting default devices (only if devices are specified)
      alsa_monitor.rules = {
        ${if cfg.systemOutput != null then ''
        {
          -- Set system output device preference
          matches = {
            { "node.name", "matches", "alsa_output.*" },
            { "device.name", "matches", "*" .. system_output .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 1000, -- Higher priority for preferred device
            ["node.description"] = "System Output - " .. system_output,
          };
        },
        '' else ""}
        ${if cfg.dawOutput != null then ''
        {
          -- Set DAW output device preference  
          matches = {
            { "node.name", "matches", "alsa_output.*" },
            { "device.name", "matches", "*" .. daw_output .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 900, -- High priority for DAW
            ["node.description"] = "DAW Output - " .. daw_output,
          };
        },
        '' else ""}
        ${if cfg.defaultInput != null then ''
        {
          -- Set default input device preference
          matches = {
            { "node.name", "matches", "alsa_input.*" },
            { "device.name", "matches", "*" .. default_input .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 1000, -- Higher priority for preferred input
            ["node.description"] = "Default Input - " .. default_input,
          };
        },
        '' else ""}
      };
      
      -- Set default sink/source based on device preferences (only if devices are specified)
      default_access.rules = {
        ${if cfg.systemOutput != null then ''
        {
          matches = {
            { "node.name", "matches", "alsa_output.*" },
            { "device.name", "matches", "*" .. system_output .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 1000,
          };
        },
        '' else ""}
        ${if cfg.defaultInput != null then ''
        {
          matches = {
            { "node.name", "matches", "alsa_input.*" },
            { "device.name", "matches", "*" .. default_input .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 1000,
          };
        },
        '' else ""}
      };
    '';
  };
} 