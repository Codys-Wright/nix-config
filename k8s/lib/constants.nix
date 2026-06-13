# Shared cluster constants — single source of truth for values that would
# otherwise be copy-pasted across every app manifest.
#
#   import ../lib/constants.nix
#
# Keep this list small: only values that (a) appear in 3+ places and (b) would
# need a coordinated edit if they ever changed.
{
  # Cloudflare tunnel target every public Ingress points external-dns at
  # (creates the proxied CNAME). One tunnel fronts the whole cluster.
  tunnelTarget = "803700ac-6ca2-4041-94c7-3d1c9ef05e52.cfargotunnel.com";

  # The NAS / control-plane node — backs direct NFS volume mounts and the
  # nas-nfs StorageClass. Prefer the nas-nfs StorageClass over raw nfs{} blocks;
  # use this constant only where a direct mount is unavoidable.
  nasServer = "10.10.10.1";
}
