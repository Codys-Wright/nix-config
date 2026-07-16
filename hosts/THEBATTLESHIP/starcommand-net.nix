{ den, ... }:
{
  den.aspects.THEBATTLESHIP-starcommand-net = {
    description = "Starcommand 10G pinning: hosts entries, WebDAV/NFS mounts, agent workspace, task env";
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Starcommand hosts Nextcloud. Keep the WebDAV URL on the canonical
        # TLS hostname, but resolve it to Starcommand's 10G/Dante address on
        # THEBATTLESHIP so traffic stays on the direct 10.10 link.
        nextcloudWebdavHost = "cloud.starcommand.live";
        nextcloudWebdavUser = "codywright";
        nextcloudWebdavMount = "/mnt/nextcloud/codywright";
        nextcloudNfsFilesMount = "/mnt/starcommand/Operations/nextcloud-data/data/${nextcloudWebdavUser}/files";
        nextcloudWebdavMediaMount = "/run/media/starcommand";
        nextcloudWebdavUrl = "https://${nextcloudWebdavHost}/remote.php/dav/files/${nextcloudWebdavUser}/";
      in
      {
        environment.variables = {
          TASK_VAULT = "${nextcloudWebdavMediaMount}/Projects";
          TASK_SERVER = "http://10.10.10.1:3456";
          NEXTCLOUD_URL = "https://cloud.starcommand.live";
          NEXTCLOUD_USER = "codywright";
          NEXTCLOUD_PASSWORD_FILE = config.sops.secrets."cody/task/nextcloud-password".path;
        };

        sops.secrets."cody/task/nextcloud-password" = {
          owner = "cody";
          group = "users";
          mode = "0400";
        };

        # Starcommand services over the 10G LAN. Keep public/certificate-valid
        # hostnames in URLs, but pin them to Starcommand's 10.10.10.1 address
        # locally so THEBATTLESHIP talks directly to nginx instead of hairpinning
        # through Cloudflare Tunnel.
        networking.hosts."10.10.10.1" = [
          "starcommand.live"
          "agent.starcommand.live"
          "audiobooks.starcommand.live"
          "auth.starcommand.live"
          "bazarr.starcommand.live"
          "bookmarks.starcommand.live"
          "chat.starcommand.live"
          "cloud.starcommand.live"
          "finance.starcommand.live"
          "git.starcommand.live"
          "grafana.starcommand.live"
          "grocy.starcommand.live"
          "hermes.starcommand.live"
          "home.starcommand.live"
          "invoice.starcommand.live"
          "jackett.starcommand.live"
          "jdownloader.starcommand.live"
          "ldap.starcommand.live"
          "lidarr.starcommand.live"
          "media.starcommand.live"
          "office.starcommand.live"
          "photos.starcommand.live"
          "radarr.starcommand.live"
          "readarr.starcommand.live"
          "signaling.starcommand.live"
          "sonarr.starcommand.live"
          "task-preview.starcommand.live"
          "task.starcommand.live"
          "torrents.starcommand.live"
          "vault.starcommand.live"
          "workspace.starcommand.live"
          "youtube.starcommand.live"
          "invoice.fasttrackaudio.com"
        ];
        services.davfs2 = {
          enable = true;
          settings.globalSection = {
            # Nextcloud works best with davfs2 client-side LOCKs disabled;
            # the server still performs normal Nextcloud/WebDAV conflict handling.
            use_locks = false;
          };
        };
        environment.etc."davfs2/secrets".source = config.sops.secrets."cody/nextcloud/davfs2-secrets".path;
        fileSystems."${nextcloudWebdavMount}" = {
          device = nextcloudWebdavUrl;
          fsType = "davfs";
          options = [
            "rw"
            "noauto"
            "nofail"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.idle-timeout=600"
            "x-systemd.requires=network-online.target"
            "x-systemd.after=network-online.target"
            "x-systemd.requires=run-secrets.d.mount"
            "x-systemd.after=run-secrets.d.mount"
            "uid=1000"
            "gid=100"
            "file_mode=0664"
            "dir_mode=0775"
          ];
        };

        fileSystems."${nextcloudWebdavMediaMount}" = {
          device = nextcloudNfsFilesMount;
          fsType = "none";
          options = [
            "bind"
            # noauto + automount: do NOT pull this bind mount in at boot.
            # Without these it mounts as part of remote-fs.target, which
            # (via the requires below) triggers the mnt-starcommand NFS mount
            # during boot. When the 10G/Dante network isn't up yet that NFS
            # mount times out (30s) and fails this dependency, stalling boot.
            # As an automount it only activates on first access instead.
            "noauto"
            "nofail"
            "_netdev"
            "x-systemd.automount"
            "x-systemd.idle-timeout=600"
            "x-systemd.requires=mnt-starcommand.mount"
            "x-systemd.after=mnt-starcommand.mount"
          ];
        };

        # Davfs2 reads credentials from /etc/davfs2/secrets. This SOPS secret
        # should contain exactly one line, for example:
        #   /mnt/nextcloud/codywright codywright <nextcloud-app-password>
        # The user-facing /run/media/starcommand mount uses the faster 10G
        # NFS view of the same Nextcloud files. Keep davfs2 available at
        # /mnt/nextcloud/codywright only for explicit WebDAV testing.
        # Do not put the app password directly in Nix; keep it in SOPS.

        # Mount starcommand storage over 10G NFS
        fileSystems."/mnt/starcommand" = {
          device = "10.10.10.1:/";
          fsType = "nfs";
          options = [
            "nfsvers=4.2"
            "rsize=1048576"
            "wsize=1048576"
            "_netdev"
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=600"
            "x-systemd.mount-timeout=30"
            "nofail"
            "soft"
            "timeo=150"
            "retrans=3"
          ];
        };

        programs.ssh.knownHosts."10.10.10.1" = {
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENFHgs8JqCE4/dO58AN8W4M2SRgetgar94m2ntI9xb8";
        };

        # Hermes workspace on THEBATTLESHIP for remote SSH execution from starcommand.
        # The agent user lands in /home/cody/agent and gets symlinks to the source
        # trees it most commonly needs without having to bounce between shells.
        systemd.tmpfiles.rules = [
          "d /mnt/nextcloud 0755 root root -"
          "d ${nextcloudWebdavMount} 0775 cody users -"
          "d ${nextcloudWebdavMediaMount} 0775 cody users -"
          "d /home/cody/agent 0755 cody users -"
          "L+ /home/cody/agent/.starcommand 0644 cody users - /home/cody/.starcommand"
          "L+ /home/cody/agent/.flake 0644 cody users - /home/cody/.flake"
          "L+ /home/cody/agent/Task 0644 cody users - /home/cody/Development/Task"
          "L+ /home/cody/agent/wiki 0644 cody users - ${nextcloudWebdavMount}"
        ];

        users.users.cody.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFrMb6rGjMO0EzWfkG71kYnkbtxW5+oIUCyaum3uHViW agent@starcommand"
        ];
      };
  };
}
