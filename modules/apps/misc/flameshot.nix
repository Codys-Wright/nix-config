# Flameshot aspect
{
  FTS.apps._.misc._.flameshot = {
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
        environment.systemPackages = [
          pkgs.flameshot
          pkgs.grim
          pkgs.slurp
        ];
      };
  };
}
