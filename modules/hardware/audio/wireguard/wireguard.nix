# WirePlumber audio device management sub-aspect (can be included independently)
{
  FTS,
  ...
}:
{
  FTS.hardware._.audio._.wireplumber = {
    description = "WirePlumber audio device management";

    nixos =
      { ... }:
      {
        # WirePlumber configuration for device management
        # Note: For device-specific configuration, you can extend this module
        # or override services.pipewire.wireplumber.extraConfig in your host config
        services.pipewire.wireplumber.extraConfig.main."50-device-preferences" = ''
          -- WirePlumber Audio Device Preferences
          -- Set default devices for different audio contexts

          -- Rules for setting default devices
          -- Add custom device preference rules here as needed
          alsa_monitor.rules = {
            -- Example: Set system output device preference
            -- {
            --   matches = {
            --     { "node.name", "matches", "alsa_output.*" },
            --     { "device.name", "matches", "*YourDeviceName*" }
            --   };
            --   apply_properties = {
            --     ["node.priority"] = 1000,
            --     ["node.description"] = "System Output - YourDeviceName",
            --   };
            -- },
          };

          -- Set default sink/source based on device preferences
          default_access.rules = {
            -- Add custom default access rules here as needed
          };
        '';
      };
  };
}
