# ProtonMail Bridge — systemd user service exposing Proton Mail via local IMAP/SMTP.
#
# After login, listens on 127.0.0.1:1143 (IMAP) and 127.0.0.1:1025 (SMTP).
# Mail clients (Nextcloud Mail, Thunderbird, mutt, etc.) connect there.
#
# Credential vault:
#   Bridge stores its vault in `pass` (gpg-backed). You must have a gpg key
#   and an initialized password store before the service can run:
#     gpg --gen-key
#     pass init <gpg-id>
#   Then perform the one-time login:
#     protonmail-bridge --cli
#     > login
#   After that the service runs --noninteractive.
#
# Headless servers: works the same — Bridge's vault is file-backed via `pass`,
# no graphical keyring required. Just make sure the service user has a gpg
# agent running (the user systemd target starts gpg-agent on demand).
{
  fleet.apps._.communications._.protonmail-bridge = {
    description = "ProtonMail Bridge — local IMAP/SMTP proxy for Proton Mail";

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = with pkgs; [
          protonmail-bridge
          pass
          gnupg
        ];

        systemd.user.services.protonmail-bridge = {
          Unit = {
            Description = "ProtonMail Bridge";
            # gpg-agent runs as a user service; wait until it's available so
            # pass can decrypt the vault on startup.
            After = [
              "network-online.target"
              "gpg-agent.service"
            ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Type = "simple";
            Restart = "always";
            RestartSec = 10;
            ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --no-window --log-level info";
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };
  };
}
