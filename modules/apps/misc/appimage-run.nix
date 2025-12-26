# AppImage Run - Run AppImage files on NixOS
{FTS, ...}: {
  FTS.apps._.misc._.appimage = {
    description = "AppImage runtime and binfmt support for NixOS";

    homeManager = {
      home.packages = [
        # Install appimage-run package
      ];
    };

    nixos = {pkgs, ...}: {
      # Install appimage-run system-wide
      environment.systemPackages = [
        pkgs.appimage-run
      ];

      # Enable AppImage support with binfmt registration
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  };
}

