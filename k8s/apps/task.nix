# Task app environments (gitops): two Argo CD Applications watching the Task
# repo's OWN Helm chart (deploy/chart/task — ships in-repo so Task stays easily
# self-hostable), plus argocd-image-updater to roll the mutable dev/latest tags
# by digest.
#
#   task-dev  follows `dev`  (trunk)      -> tasks-dev.starcommand.live (+ ui-lab)
#   task      follows `main` (production) -> task.starcommand.live
#
# No secrets ride along — the repo and images are public. Moved off the host
# k3s-manifests bridge into nixidy; Argo now manages these Applications.
{ ... }:
let
  tunnelTarget = (import ../lib/constants.nix).tunnelTarget;
  registry = "registry.starcommand.live:30050";
in
{
  applications.task = {
    namespace = "argocd";
    createNamespace = false;

    yamls = [
      ''
        apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: task-dev
          namespace: argocd
          annotations:
            # Continuous deployment: track the mutable `dev` tags BY DIGEST — a
            # new CI push to the registry rolls the pods. write-back-method
            # argocd mutates Application parameters (no git commits → branch
            # protection stays intact).
            argocd-image-updater.argoproj.io/image-list: >-
              server=${registry}/task-server:dev,
              web=${registry}/task-web:dev,
              uilab=${registry}/task-ui-lab:dev
            argocd-image-updater.argoproj.io/server.update-strategy: digest
            argocd-image-updater.argoproj.io/server.helm.image-name: server.image.repository
            argocd-image-updater.argoproj.io/server.helm.image-tag: server.image.tag
            argocd-image-updater.argoproj.io/web.update-strategy: digest
            argocd-image-updater.argoproj.io/web.helm.image-name: web.image.repository
            argocd-image-updater.argoproj.io/web.helm.image-tag: web.image.tag
            argocd-image-updater.argoproj.io/uilab.update-strategy: digest
            argocd-image-updater.argoproj.io/uilab.helm.image-name: uiLab.image.repository
            argocd-image-updater.argoproj.io/uilab.helm.image-tag: uiLab.image.tag
            argocd-image-updater.argoproj.io/write-back-method: argocd
        spec:
          project: default
          source:
            repoURL: https://codeberg.org/FastTrackStudios/Task.git
            targetRevision: dev
            path: deploy/chart/task
            helm:
              values: |
                image:
                  registry: ${registry}
                server:
                  image:
                    tag: dev
                  publicUrl: https://tasks-dev.starcommand.live
                  persistence:
                    size: 10Gi
                web:
                  image:
                    tag: dev
                uiLab:
                  enabled: true
                  host: tasks-lab.starcommand.live
                  image:
                    tag: dev
                ingress:
                  className: traefik
                  host: tasks-dev.starcommand.live
                  annotations:
                    external-dns.alpha.kubernetes.io/target: ${tunnelTarget}
          destination:
            server: https://kubernetes.default.svc
            namespace: task-dev
          syncPolicy:
            automated:
              prune: true
              selfHeal: true
            syncOptions:
              - CreateNamespace=true
      ''
      ''
        apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: task
          namespace: argocd
          annotations:
            argocd-image-updater.argoproj.io/image-list: >-
              server=${registry}/task-server:latest,
              web=${registry}/task-web:latest
            argocd-image-updater.argoproj.io/server.update-strategy: digest
            argocd-image-updater.argoproj.io/server.helm.image-name: server.image.repository
            argocd-image-updater.argoproj.io/server.helm.image-tag: server.image.tag
            argocd-image-updater.argoproj.io/web.update-strategy: digest
            argocd-image-updater.argoproj.io/web.helm.image-name: web.image.repository
            argocd-image-updater.argoproj.io/web.helm.image-tag: web.image.tag
            argocd-image-updater.argoproj.io/write-back-method: argocd
        spec:
          project: default
          source:
            repoURL: https://codeberg.org/FastTrackStudios/Task.git
            targetRevision: main
            path: deploy/chart/task
            helm:
              values: |
                image:
                  registry: ${registry}
                server:
                  image:
                    tag: latest
                  publicUrl: https://task.starcommand.live
                  persistence:
                    size: 50Gi
                  resources:
                    requests:
                      cpu: 250m
                      memory: 512Mi
                    limits:
                      memory: 2Gi
                web:
                  image:
                    tag: latest
                uiLab:
                  enabled: false
                ingress:
                  className: traefik
                  host: task.starcommand.live
                  annotations:
                    external-dns.alpha.kubernetes.io/target: ${tunnelTarget}
                backup:
                  git:
                    # Snapshots COMMIT LOCALLY to the PV's .gitstate (per-org +
                    # full-state history — the valuable part) but PUSH NOWHERE.
                    # An empty remoteBase makes the engine skip the push phase.
                    enabled: true
                    remoteBase: ""
                    fullRepo: task-data
                    existingSecret: task-git-backup
          destination:
            server: https://kubernetes.default.svc
            namespace: task
          syncPolicy:
            automated:
              prune: true
              selfHeal: true
            syncOptions:
              - CreateNamespace=true
      ''
      ''
        apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
          name: argocd-image-updater
          namespace: argocd
        spec:
          project: default
          source:
            repoURL: https://argoproj.github.io/argo-helm
            chart: argocd-image-updater
            targetRevision: 0.12.3
            helm:
              values: |
                config:
                  registries:
                    # The in-cluster registry holding our deployment images.
                    # Plain HTTP on the LAN NodePort.
                    - name: lan
                      prefix: ${registry}
                      api_url: http://10.10.10.1:30050
                      insecure: true
                      default: true
          destination:
            server: https://kubernetes.default.svc
            namespace: argocd
          syncPolicy:
            automated:
              prune: true
              selfHeal: true
      ''
    ];
  };
}
