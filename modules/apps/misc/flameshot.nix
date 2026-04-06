# Flameshot aspect
{
  fleet.apps._.misc._.flameshot = {
    description = "Flameshot - Powerful yet simple to use screenshot software";

    homeManager =
      { pkgs, config, ... }:
      {
        home.packages = [ pkgs.flameshot ];

        # Configure flameshot for Wayland
        xdg.configFile."flameshot/flameshot.ini".text = ''
          [General]
          useGrimAdapter=true
          disabledTrayIcon=false
          showStartupLaunchMessage=false
        '';
      };

    nixos =
      { pkgs, ... }:
      {
        # grim/slurp are Wayland screenshot dependencies needed system-wide
        environment.systemPackages = [
          pkgs.grim
          pkgs.slurp
        ];
      };
  };
}
