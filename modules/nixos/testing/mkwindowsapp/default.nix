{ config, pkgs, lib, inputs, ... }:

# Testing module for mkWindowsApp from erosanix
# This demonstrates how to access and use mkWindowsApp in a NixOS module

let
  # Access mkWindowsApp from erosanix inputs
  mkWindowsApp = inputs.erosanix.lib.${pkgs.system}.mkWindowsAppNoCC;
  copyDesktopIcons = inputs.erosanix.lib.${pkgs.system}.copyDesktopIcons;
  
  # Example package using mkWindowsApp - you can replace this with your actual audio plugin
  test-windows-app = mkWindowsApp {
    pname = "test-windows-app";
    version = "1.0.0";
    
    # Replace this with your actual Windows app installer
    src = pkgs.fetchurl {
      url = "https://example.com/your-app-installer.exe";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
    };
    
    wine = pkgs.wineWowPackages.full;
    wineArch = "win64";
    dontUnpack = true;
    
    # Installation script - customize this for your app
    winAppInstall = ''
      # Install any required fonts or dependencies
      winetricks corefonts
      wineserver -w
      
      # Run the installer
      wine start /unix ${pkgs.fetchurl {
        url = "https://example.com/your-app-installer.exe";
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      }} /S
      wineserver -w
      
      # Clean up any unwanted files
      rm -f "$WINEPREFIX/drive_c/delete-this-file"
    '';
    
    # Run script - customize this for your app
    winAppRun = ''
      # The following filesystem changes will happen in the read-write layer, and will not be persisted.
      rm -fR "$WINEPREFIX/drive_c/users/$USER/Application Data/test-app"
      
      # This is an example of setting up data to be persisted in the user's home directory.
      mkdir -p "$HOME/.config/test-app"
      ln -s -v "$HOME/.config/test-app" "$WINEPREFIX/drive_c/users/$USER/Application Data/"
      
      # Run the application
      wine start /unix "$WINEPREFIX/drive_c/Program Files/TestApp/test-app.exe" "$ARGS"
    '';
    
    installPhase = ''
      runHook preInstall
      
      # .launcher is the script created by mkWindowsApp. DO NOT RENAME OR DELETE THIS FILE!
      # It's used in the input hash for the app layer, so that the garbage collector knows
      # not to delete the layer.
      # Instead, link to it.
      ln -s $out/bin/.launcher $out/bin/test-windows-app
      
      runHook postInstall
    '';
    
    meta = with lib; {
      description = "Test Windows application packaged with mkWindowsApp";
      homepage = "https://example.com";
      license = licenses.unfree;
      maintainers = [ ];
      platforms = [ "x86_64-linux" "i386-linux" ];
    };
  };
in
{
  options.testing.mkwindowsapp = {
    enable = lib.mkEnableOption "mkWindowsApp testing module";
  };
  
  config = lib.mkIf config.testing.mkwindowsapp.enable {
    # Make the test package available
    environment.systemPackages = [ test-windows-app ];
    
    # You can also add it to home-manager packages if you're using home-manager
    # home-manager.users.${config.users.users.defaultUser.name}.home.packages = [ test-windows-app ];
  };
}
