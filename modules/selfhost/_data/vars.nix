# Shared selfhost variables (domains, subdomains) — imported by
# modules/selfhost/selfhost.nix and modules/selfhost/stacks/*.nix.
# Underscore-prefixed directory: ignored by import-tree.
{
  domain = "starcommand.live";
  nextcloudSubdomain = "cloud";
  lldapSubdomain = "ldap";
  authSubdomain = "auth";
  grafanaSubdomain = "grafana";
  vaultwardenSubdomain = "vault";
  jellyfinSubdomain = "media";
  grocySubdomain = "grocy";
  delugeSubdomain = "torrents";
  forgejoSubdomain = "git";
  karakeepSubdomain = "bookmarks";
  audiobookshelfSubdomain = "audiobooks";
  hledgerSubdomain = "finance";
  homeAssistantSubdomain = "home";
  openWebuiSubdomain = "chat";
  pinchflatSubdomain = "youtube";
  immichSubdomain = "photos";
}
