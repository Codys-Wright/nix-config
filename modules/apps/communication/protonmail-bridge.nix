# ProtonMail Bridge — local IMAP/SMTP proxy for Proton Mail.
#
# Thin wrapper over the upstream home-manager module
# `services.protonmail-bridge` (merged to home-manager master 2025-08-17,
# nix-community/home-manager#7674). We:
#
#   - Add `pass` + `gnupg` to the service PATH so Bridge's keychain helper
#     can find a vault when no gnome-keyring / kwallet is present.
#   - Override the Install target so the service works on headless servers
#     with a lingering user (default.target) as well as graphical sessions.
#
# One-time setup after the first activation:
#
#   # As the user running Bridge (cody, starcommand, etc.):
#   gpg --batch --passphrase '' --quick-gen-key \
#       "Bridge <bridge@$(hostname)>" default default 0
#   pass init $(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/ {print $10; exit}')
#   systemctl --user stop protonmail-bridge
#   protonmail-bridge --cli
#     > login         # paste Proton credentials + 2FA
#     > info <email>  # copy the Bridge IMAP/SMTP password
#     > quit
#   systemctl --user start protonmail-bridge
#
# Bridge listens on 127.0.0.1:1143 (IMAP) and 127.0.0.1:1025 (SMTP).
{
  fleet.apps._.communications._.protonmail-bridge = {
    description = "ProtonMail Bridge — local IMAP/SMTP proxy for Proton Mail";

    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      {
        services.protonmail-bridge = {
          enable = true;
          extraPackages = with pkgs; [
            pass
            gnupg
          ];
          logLevel = "info";
        };

        # Upstream defaults to graphical-session.target. On lingering server
        # users (no graphical session) that target never activates — force
        # default.target so Bridge starts on boot everywhere.
        systemd.user.services.protonmail-bridge = {
          Unit.After = lib.mkForce [ "network-online.target" ];
          Unit.Wants = [ "network-online.target" ];
          Install.WantedBy = lib.mkForce [ "default.target" ];
        };
      };
  };
}
