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
    systemOutput = mkStrOpt "Yamaha TF Multichannel" "Default system output device name";
    dawOutput = mkStrOpt "Yamaha TF Multichannel" "Default DAW output device name";
    defaultInput = mkStrOpt "Yamaha TF Multichannel" "Default input device name";
  };

  config = mkIf cfg.enable {
    # WirePlumber configuration for device management
    services.pipewire.wireplumber.extraLuaConfig.main."50-device-preferences" = ''
      -- WireGuard Audio Device Preferences
      -- Set default devices for different audio contexts
      
      -- Default device preferences
      local system_output = "${cfg.systemOutput}"
      local daw_output = "${cfg.dawOutput}"
      local default_input = "${cfg.defaultInput}"
      
      -- Rules for setting default devices
      alsa_monitor.rules = {
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
      };
      
      -- Set default sink/source based on device preferences
      default_access.rules = {
        {
          matches = {
            { "node.name", "matches", "alsa_output.*" },
            { "device.name", "matches", "*" .. system_output .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 1000,
          };
        },
        {
          matches = {
            { "node.name", "matches", "alsa_input.*" },
            { "device.name", "matches", "*" .. default_input .. "*" }
          };
          apply_properties = {
            ["node.priority"] = 1000,
          };
        },
      };
    '';
  };
} 