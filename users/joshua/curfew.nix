# Joshua's login-hours enforcement (pam_time gate + session-termination timer).
{ ... }:
{
  den.aspects.joshua-curfew = {
    description = "Joshua's login curfew — pam_time 08:00-22:00 window plus a timer that terminates out-of-hours sessions";

    nixos =
      { pkgs, ... }:
      {
        # Allow Joshua to log in only between 08:00 and 22:00.
        environment.etc."security/time.conf".text = ''
          sddm ; * ; joshua ; Al0800-2200
        '';

        security.pam.services.sddm.text = ''
          auth      substack      login
          account   include       login
          password  substack      login
          session   include       login
          account   required      pam_time.so conffile=/etc/security/time.conf
        '';

        systemd.services.joshua-curfew = {
          description = "Terminate Joshua sessions outside allowed hours";
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            hour="$(${pkgs.coreutils}/bin/date +%H)"
            if [ "$hour" -lt 8 ] || [ "$hour" -ge 22 ]; then
              ${pkgs.systemd}/bin/loginctl terminate-user joshua || true
            fi
          '';
        };

        systemd.timers.joshua-curfew = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1m";
            OnUnitActiveSec = "1m";
            Unit = "joshua-curfew.service";
          };
        };
      };
  };
}
