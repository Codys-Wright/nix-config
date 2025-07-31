{
  config,
  lib,
  osConfig,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  snowfallorg.user.enable = true;
  
  FTS-FLEET = {
    bundles = {
      common = enabled;
      shell = enabled;
      browsers = enabled;
      # desktop.hyprland = enabled; # Disabled - using KDE
      development = enabled;
      office = enabled;
    };

    programs = {
      git = enabled;
      spotify = enabled;
    };
    
    config.user = {
      enable = true;
      name = "cody";
      fullName = "Cody Wright";
      email = "cody@example.com"; # Update this with your actual email
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");
} 