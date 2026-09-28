{ den, inputs, ... }:
let
  # Soft vars from the private nix-secrets flake (networking topology).
  domain = inputs.nix-secrets.networking.domains.selfhost;
  starcommandIp = inputs.nix-secrets.networking.hosts.starcommand.vpnIp;
in
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
        nextcloudWebdavHost = "cloud.${domain}";
        nextcloudWebdavUser = "codywright";
        nextcloudWebdavMount = "/mnt/nextcloud/codywright";
        nextcloudNfsFilesMount = "/mnt/starcommand/Operations/nextcloud-data/data/${nextcloudWebdavUser}/files";
        nextcloudWebdavMediaMount = "/run/media/starcommand";
        nextcloudWebdavUrl = "https://${nextcloudWebdavHost}/remote.php/dav/files/${nextcloudWebdavUser}/";
      in
      {
        # TEMPORARY: testing the new cluster Pi-hole (2 replicas behind a
        # MetalLB floating IP, see ~/.starcommand modules/services/pihole)
        # before pointing the whole network's DHCP DNS at it. Revert this
        # (or just delete the line) once satisfied — the router's DHCP DNS
        # server settings are the real switch-over; this only affects
        # THEBATTLESHIP itself.
        networking.nameservers = [ "192.168.1.254" ];

        environment.variables = {
          TASK_VAULT = "${nextcloudWebdavMediaMount}/Projects";
          TASK_SERVER = "http://${starcommandIp}:3456";
          NEXTCLOUD_URL = "https://cloud.${domain}";
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
        networking.hosts."${starcommandIp}" = [
          "${domain}"
          "agent.${domain}"
          "audiobooks.${domain}"
          "auth.${domain}"
          "bazarr.${domain}"
          "bookmarks.${domain}"
          "chat.${domain}"
          "cloud.${domain}"
          "finance.${domain}"
          "git.${domain}"
          "grafana.${domain}"
          "grocy.${domain}"
          "hermes.${domain}"
          "home.${domain}"
          "invoice.${domain}"
          "jackett.${domain}"
          "jdownloader.${domain}"
          "ldap.${domain}"
          "lidarr.${domain}"
          "media.${domain}"
          "office.${domain}"
          "photos.${domain}"
          "radarr.${domain}"
          "readarr.${domain}"
          "signaling.${domain}"
          "sonarr.${domain}"
          "task-preview.${domain}"
          "task.${domain}"
          "torrents.${domain}"
          "vault.${domain}"
          "workspace.${domain}"
          "youtube.${domain}"
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
          device = "${starcommandIp}:/";
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

        programs.ssh.knownHosts."${starcommandIp}" = {
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
