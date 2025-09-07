{ config, pkgs, lib, inputs, ... }:

# Module to demonstrate using mkWindowsApp from erosanix
# This shows how to access the mkWindowsApp function from inputs

let
  # Access mkWindowsApp from erosanix inputs
  mkWindowsApp = inputs.erosanix.lib.${pkgs.system}.mkWindowsAppNoCC;
  
  # Example package using mkWindowsApp
  example-windows-app = mkWindowsApp {
    pname = "example-windows-app";
    version = "1.0.0";
    
    # You would replace this with your actual Windows app installer
    src = pkgs.fetchurl {
      url = "https://example.com/your-app-installer.exe";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Replace with actual hash
    };
    
    wine = pkgs.wineWowPackages.full;
    wineArch = "win64";
    dontUnpack = true;
    persistRegistry = true;
    
    # Installation script
    winAppInstall = ''
      # Run the installer
      wine "$src"
      
      # Wait for installation
      sleep 10
      
      echo "Installation completed"
    '';
    
    # Map persistent directories
    fileMap = {
      "$HOME/.config/example-app" = "drive_c/users/$USER/AppData/Roaming/ExampleApp";
    };
    
    # Desktop integration
    nativeBuildInputs = [ 
      pkgs.copyDesktopItems 
      inputs.erosanix.lib.${pkgs.system}.copyDesktopIcons 
    ];
    
    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "example-windows-app";
        desktopName = "Example Windows App";
        comment = "An example Windows application packaged with mkWindowsApp";
        categories = [ "Application" ];
        icon = "example-app";
      })
    ];
    
    meta = with lib; {
      description = "Example Windows application packaged with mkWindowsApp";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  };
in
{
  options.programs.mkwindowsapp = {
    enable = lib.mkEnableOption "mkWindowsApp example module";
  };
  
  config = lib.mkIf config.programs.mkwindowsapp.enable {
    # Make the example package available
    environment.systemPackages = [ example-windows-app ];
    
    # You could also add it to home-manager packages if you're using home-manager
    # home-manager.users.${config.users.users.defaultUser.name}.home.packages = [ example-windows-app ];
  };
}
