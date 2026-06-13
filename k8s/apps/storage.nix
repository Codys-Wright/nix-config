# Cluster storage: csi-driver-nfs against starcommand's NAS.
#
# StorageClass names express INTENT (docs/cluster-design.md, "Storage
# evolution"): workloads bind to `nas-nfs`, never to a node. When a replica
# storage server exists, this file is where the backend swaps.
#
# THEBATTLESHIP mounts ride the 10G link (10.10.10.1); the export squashes
# everyone to root so PV permissions are a non-issue.
{ charts, ... }:
{
  applications.storage = {
    namespace = "kube-system";
    helm.releases.csi-driver-nfs = {
      chart = charts.kubernetes-csi.csi-driver-nfs;
      values = {
        # The node plugin must run on every node, including tainted
        # opportunistic agents — volumes have to mount on THEBATTLESHIP too.
        node.tolerations = [
          {
            key = "fleet.fts/opportunistic";
            operator = "Exists";
            effect = "NoSchedule";
          }
        ];
      };
    };

    # SQLite/embedded-DB config dirs go here, NOT on NFS (NFS file locking
    # corrupts SQLite — pinchflat/arr "database is locked"). local-path pins
    # the pod to starcommand, fine while it is the only anchor.
    resources.storageClasses.db-local = {
      provisioner = "rancher.io/local-path";
      reclaimPolicy = "Retain";
      volumeBindingMode = "WaitForFirstConsumer";
    };

    resources.storageClasses.nas-nfs = {
      provisioner = "nfs.csi.k8s.io";
      parameters = {
        server = (import ../lib/constants.nix).nasServer;
        # The export carries fsid=0, making /mnt/storage the NFSv4
        # pseudo-root: v4 clients mount "/" (paths relative to the root).
        share = "/";
        subDir = "k8s/\${pvc.metadata.namespace}-\${pvc.metadata.name}";
      };
      reclaimPolicy = "Retain";
      volumeBindingMode = "Immediate";
      mountOptions = [
        "nfsvers=4.2"
        "hard"
        "noatime"
      ];
    };
  };
}
