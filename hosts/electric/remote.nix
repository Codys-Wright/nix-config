# electric runs unattended: carter logs in by himself and the session never
# locks, and the desktop can be seen and driven over SSH (root) whatever the
# compositor:
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
    description = "carter on electric: autologin, GNOME never locks or blanks";

    includes = [ <fleet.user/autologin> ];

    homeManager = {
      dconf.settings = {
        "org/gnome/desktop/screensaver".lock-enabled = false;
        "org/gnome/desktop/session".idle-delay = 0;
        "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
      };
    };
  };
}
