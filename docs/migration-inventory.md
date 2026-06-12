# Wave 3+4 Migration Inventory (generated 2026-06-12)

See git history of this file for the full agent report. Key operational facts:

## Databases on host postgres 17.6 (unix socket peer auth; TCP loopback only for vaultwarden)
nextcloud, forgejo, authelia, grafana, vaultwarden, immich.
pg dumps daily 02:00 -> /mnt/disks/parity/backups/postgresql for [nextcloud authelia forgejo immich] (grafana+vaultwarden NOT dumped).

## Redis (all unix-socket-only): redis-nextcloud, redis-authelia, redis-immich.

## Wave 3 targets
- forgejo 15.0.1: unix socket /run/forgejo/forgejo.sock, state /var/lib/forgejo, pg db forgejo,
  OIDC client forgejo (redirect /user/oauth2/SHB-Authelia/callback, one_factor, no pkce).
  HAZARDS: hermes-forgejo-* units hardcode https://git.starcommand.live (12 identities + webhook 127.0.0.1:8793);
  THEBATTLESHIP runner registered to that URL; codeberg push-mirrors push to it; serverAliases git.fasttrackstudio.app;
  hourly forgejo-dump to /var/lib/forgejo/dump (restic source); ssh access via host sshd user forgejo.
- immich 2.1.0: port 2283, state /var/lib/immich, media /mnt/storage/Operations/photos, pg+redis-immich,
  ML on :3003. OIDC client immich (claims_policy immich_policy + scope immich_scope, client_secret_post,
  redirects /auth/login /user-settings app.immich:///oauth-callback). nginx 50G body. Groups immich_user/admin.
- monitoring: grafana 12.2 :3100 (pg db grafana, OIDC pkce S256 client_secret_basic, claims grafana_groups),
  prometheus :3001 (0.0.0.0!), loki :3002 (index/chunks in /tmp = ephemeral), promtail :9080.
  Scrapes host exporters on 127.0.0.1 — migrating grafana orphans them; keep prometheus host-side or bridge.
- vaultwarden 1.34.3 :8222: pg via TCP 127.0.0.1 (the reason enableTCPIP), /var/lib/vaultwarden,
  forward-auth (admin two_factor vaultwarden_admin, rest bypass).
- home-assistant :8123: sqlite in /var/lib/hass, LDAP via lldap web API :17170 command_line script,
  wyoming whisper :10300 piper :10200 openwakeword :10400 (0.0.0.0 binds). Likely keep on host (devices/voice).
- arr stack (radarr 7878, sonarr 8989, bazarr 6767, readarr 8787, lidarr 8686, jackett 9117):
  sqlite states /var/lib/<app>, forward-auth (bypass ^/api ^/feed, two_factor arr_user),
  api_key sops for radarr/sonarr/jackett. media group. deluge Label plugin interplay.
- deluge + VPN: gluetun sidecar candidate. openvpn creds sops starcommand/selfhost/openvpn/{username,password},
  ProtonVPN TCP 443/7770/8443, deluge web 8112 daemon 58846 listen 6881-6889,
  download /mnt/storage/Operations/torrents, outgoing_interface=tun0 kill-switch semantics.

## Wave 4
- nextcloud 31.0.9 php-fpm: data bind-mount /var/lib/nextcloud/data -> /mnt/storage/Operations/nextcloud-data/data,
  pg + redis-nextcloud, cron timers, mail via ProtonMail Bridge 127.0.0.1:1143/1025 (bridge cert wiring),
  files_external SQL oneshot, oidc_login client nextcloud (claims nextcloud_userinfo, pkce S256),
  LDAP app -> 127.0.0.1:3890, alias cloud.fasttrackaudio.com (separate LE cert + trusted_domains),
  apps: mail, previewgenerator, richdocuments(collabora), spreed(talk), context_chat.
- collabora: podman collabora/code:latest 127.0.0.1:9980, stateless, WOPI host-gateway hack, nginx ws locations.
- talk-hpb: nats :4222, coturn :3478+relay 49152-49172/udp (firewall!), janus lo:8088, signaling 127.0.0.1:8188.
  SECRETS ARE PLAINTEXT NIX STRINGS (nix-secrets soft tier) — move to sops/k8s Secrets during migration.
- context-chat-backend: podman --network=host APP_PORT 10034, podman volume context_chat_backend_data,
  APP_SECRET plaintext soft tier, ollama 127.0.0.1:11434 (now 0.0.0.0).
- lldap 0.6.2 (STAYS host): 127.0.0.1:3890 + web 17170, sqlite /var/lib/lldap (NO backup — gap),
  11 users + groups declarative. Now also listens 0.0.0.0 (wave2 bridge) fw-scoped.
- authelia 4.39.12 (STAYS host): 127.0.0.1:9091, pg authelia + redis-authelia + lldap,
  defaultPolicy deny, parent rules selfhost.nix:469-565, oidc clients forgejo/nextcloud/immich/grafana + bridges.

## Cross-cutting hazards
- networking.hosts 127.0.0.1 aliases for auth/ldap/cloud on host — migrated apps use public DNS instead.
- Removing a service: sweep restic instance + postgresqlBackup list + tunnel manualIngress entries +
  prometheus scrape jobs + lldap group references + parent secret decls (mkBackup references break eval).
- Backup gaps today: /var/lib/immich, /var/lib/hass, lldap sqlite, grafana DB, vaultwarden DB.
