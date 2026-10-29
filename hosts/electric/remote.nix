# electric runs unattended: carter logs in by himself and the session never
# locks or blanks, and the desktop can be seen and driven over SSH: cua-driver
# (<fleet.system/cua-desktop>), or as root whatever the compositor:
#   screenshot: ffmpeg -f kmsgrab -i - -vf hwdownload,format=bgr0 -frames:v 1 shot.png
#   input:      ydotool click / type / mousemove (ydotoold runs as a service)
# Interactive remote desktop is Sunshine (from <fleet/gaming>) + Moonlight.
{ __findFile, ... }:
{
  den.aspects.electric-remote = {
    description = "Unattended electric: carter autologin, no screen lock, KMS screenshots + ydotool over SSH";

    nixos =
      { pkgs, ... }:
      {
        programs.ydotool.enable = true;
        environment.systemPackages = [ pkgs.ffmpeg ];
      };
  };

  den.aspects.carter-electric-unattended = {
    description = "carter on electric: autologin, Loft never locks or turns the screen off";

    includes = [ <fleet.user/autologin> ];

    homeManager.programs.loft.idle = {
      lockAfter = null;
      screenOffAfter = null;
    };
  };
}
