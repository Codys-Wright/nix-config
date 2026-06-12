# Database layer for wave-3+ apps: CloudNativePG operator + the shared
# postgres cluster. Postgres data lives on local-path (NVMe on starcommand)
# — never on NFS — with nightly dumps to the NAS.
{ charts, lib, ... }:
{
  applications.cnpg = {
    namespace = "cnpg-system";
    createNamespace = true;
    helm.releases.cloudnative-pg = {
      chart = charts.cloudnative-pg.cloudnative-pg;
      # CNPG CRDs blow the client-side-apply annotation limit
      transformer = map (
        m:
        if m.kind == "CustomResourceDefinition" then
          lib.recursiveUpdate m {
            metadata.annotations."argocd.argoproj.io/sync-options" = "ServerSideApply=true";
          }
        else
          m
      );
      values = {
        crds.create = true;
        # operator on the always-on node
        nodeSelector."kubernetes.io/hostname" = "starcommand";
      };
    };
  };

  applications.databases = {
    namespace = "databases";
    createNamespace = true;

    resources.persistentVolumeClaims."pg-dumps".spec = {
      accessModes = [ "ReadWriteMany" ];
      storageClassName = "nas-nfs";
      resources.requests.storage = "20Gi";
    };

    yamls = [
      # Shared cluster for migrated apps (forgejo, immich, later nextcloud).
      # Single instance while starcommand is the only anchor; bump
      # `instances` when more always-on nodes exist.
      ''
        apiVersion: postgresql.cnpg.io/v1
        kind: Cluster
        metadata:
          name: pg-main
          namespace: databases
        spec:
          instances: 1
          imageName: ghcr.io/cloudnative-pg/postgresql:16
          enableSuperuserAccess: true
          storage:
            storageClass: local-path
            size: 30Gi
          affinity:
            nodeSelector:
              kubernetes.io/hostname: starcommand
          postgresql:
            parameters:
              max_connections: "200"
          managed:
            roles:
              - name: vaultwarden
                ensure: present
                login: true
                passwordSecret:
                  name: vaultwarden-pg


        apiVersion: postgresql.cnpg.io/v1
        kind: Database
        metadata:
          name: pg-main-vaultwarden
          namespace: databases
        spec:
          name: vaultwarden
          owner: vaultwarden
          cluster:
            name: pg-main
      ''
      # Nightly logical dumps of every database to the NAS.
      ''
        apiVersion: batch/v1
        kind: CronJob
        metadata:
          name: pg-dumpall
          namespace: databases
        spec:
          schedule: "30 4 * * *"
          concurrencyPolicy: Forbid
          successfulJobsHistoryLimit: 2
          failedJobsHistoryLimit: 2
          jobTemplate:
            spec:
              template:
                spec:
                  restartPolicy: Never
                  enableServiceLinks: false
                  containers:
                    - name: dump
                      image: ghcr.io/cloudnative-pg/postgresql:16
                      command:
                        - /bin/sh
                        - -c
                        - >
                          pg_dumpall -h pg-main-rw -U postgres
                          | gzip > /dumps/pg-main-$(date +%w).sql.gz
                      env:
                        - name: PGPASSWORD
                          valueFrom:
                            secretKeyRef:
                              name: pg-main-superuser
                              key: password
                      volumeMounts:
                        - name: dumps
                          mountPath: /dumps
                  volumes:
                    - name: dumps
                      persistentVolumeClaim:
                        claimName: pg-dumps
      ''
    ];
  };
}
