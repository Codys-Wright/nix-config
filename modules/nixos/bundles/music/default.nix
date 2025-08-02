{ lib, inputs, ... }:
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  musnix.enable = true;
  musnix.kernel.realtime = false;

  environment.variables = let
    makePluginPath = format:
      (lib.strings.makeSearchPath format [
        "$HOME/.nix-profile/lib"
        "/run/current-system/sw/lib"
        "/etc/profiles/per-user/$USER/lib"
      ])
      + ":$HOME/.${format}";
  in {
    DSSI_PATH   = lib.mkForce (makePluginPath "dssi");
    LADSPA_PATH = lib.mkForce (makePluginPath "ladspa");
    LV2_PATH    = lib.mkForce (makePluginPath "lv2");
    LXVST_PATH  = lib.mkForce (makePluginPath "lxvst");
    VST_PATH    = lib.mkForce (makePluginPath "vst");
    VST3_PATH   = lib.mkForce (makePluginPath "vst3");
  };
}