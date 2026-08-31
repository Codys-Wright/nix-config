# Task app environments (gitops): two Argo CD Applications watching the Task
# repo's OWN Helm chart (deploy/chart/task — ships in-repo so Task stays easily
# self-hostable), plus argocd-image-updater to roll the mutable dev/latest tags
# by digest.
#
# SOURCE OF TRUTH IS GITHUB. It pointed at codeberg.org/FastTrackStudios/Task
# — which predates the August 2026 split and became a THIRD source of truth:
# the deploy workflow pushed images from the GitHub repo while Argo synced
# manifests from Codeberg, so production froze on the last pre-split image and
# every "Verify live" step timed out. That was fixed once (5ba58126) and then
# lost to a blanket revert (2f2fa71e) that was really aimed at unrelated
# changes in the same commit. Restored here.
#
# The path is `deploy/chart/task`, NOT `apps/deploy/chart/task`: the Task repo
# refactored to one workspace at the root and moved apps/deploy -> deploy. The
# live cluster was left pointing at the old path, which no longer exists, so
# Argo kept serving a pre-refactor chart revision — which is why /otlp and
# /media were missing from the ingress even though the chart declares them.
#
# task-dev follows `main` too: the new repo has only main, and the dev/prod
# split is by image channel tag (:dev vs :latest), not by branch.
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
  # NB: the nixidy app name MUST differ from every inner Application name
  # (task-dev / task / argocd-image-updater) — the app-of-apps creates a wrapper
  # Application of this same name, which would otherwise collide with the inner
  # "task" Application. Hence "task-apps".
  applications.task-apps = {
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
            repoURL: https://github.com/FastTrackStudios/task.git
            targetRevision: main
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
            repoURL: https://github.com/FastTrackStudios/task.git
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
                  env:
                    # Permission enforcement (FastTrackStudio issue #109).
                    # Until this was set the gate evaluated every RPC,
                    # recorded the answer, and dispatched anyway — which is
                    # how this server served every org's data to anonymous
                    # visitors while the audit log said would_deny ~1000
                    # times an hour. Verified per-org in Tempo before
                    # flipping: a signed-in session resolves on its home org
                    # and the cross-org fan-out is gone. DO NOT UNSET.
                    TASK_ENFORCE_PERMISSIONS: "1"
                    # Signed-URL enforcement for the colocated media route.
                    # TASK_ENFORCE_PERMISSIONS does NOT reach it —
                    # /org/{slug}/media/{path} is plain HTTP, not vox — so
                    # until this was set it served the org's entire
                    # resources/ tree, files and listings, to anyone
                    # (confirmed open on prod with a bare curl 2026-08-07).
                    # Clients mint a short-lived grant over vox and append
                    # ?token=. Fails SOFT, so the failure mode is songs
                    # 401ing, not the app breaking. DO NOT UNSET.
                    TASK_ENFORCE_MEDIA_TOKEN: "1"
                    # Hermes agent gateway — the default chat backend for
                    # /agents. Its bearer key rides the task-env Secret.
                    TASK_HERMES_URL: http://hermes-gateway.hermes.svc:8642/v1
                    # OpenTelemetry. architect-telemetry's OTLP pipelines are
                    # inert unless this is set, so this is what actually turns
                    # tracing on. The collector fans traces/logs/metrics out
                    # to Tempo/Loki/Prometheus — the app never names a
                    # backend.
                    #
                    # NOTE: the chart's values-prod.yaml is an EXAMPLE for
                    # self-hosters. These inline values are what this cluster
                    # actually runs, so prod env belongs HERE, not there.
                    OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector.observability.svc:4318
                    OTEL_EXPORTER_OTLP_PROTOCOL: http/protobuf
                    OTEL_RESOURCE_ATTRIBUTES: deployment.environment=prod,service.namespace=task
                    # Authenticated OTLP ingest for out-of-cluster CLIENTS
                    # (desktop, iOS): mounts /otlp/v1/* on the server,
                    # forwarding here. The collector stays a ClusterIP —
                    # clients reuse the server's auth and TLS rather than a
                    # public write endpoint. This is what the five iOS apps
                    # bake TASK_OTLP_ENDPOINT against.
                    TASK_OTLP_UPSTREAM: http://otel-collector.observability.svc:4318
                    # Announce the NAS mount as a Storage Location volume.
                    # Mounting it (mediaMounts) only makes the bytes
                    # reachable; a File Root can only be granted on a volume
                    # an AGENT ANNOUNCED, and the in-server agent announces
                    # just its own PVC. Without this the whole media tree is
                    # invisible to the placement registry. Must match a
                    # mediaMounts mountPath — a root stores the path it was
                    # created at.
                    TASK_STORAGE_VOLUMES: media=/mnt/storage/Task
                    TASK_STORAGE_GRANTS: >-
                      cbu@media:Projects/cbu,
                      codywright@media:Projects/codywright,
                      days-to-praise@media:Projects/days-to-praise,
                      fasttrackaudio@media:Projects/fasttrackaudio,
                      fasttrackstudios@media:Projects/fasttrackstudios,
                      tombrooksmusic@media:Projects/tombrooksmusic
                  # Carries TASK_HERMES_API_KEY, TASK_MCP_TOKEN and
                  # TASK_OTLP_TOKEN (the static ingest bearer the iOS/desktop
                  # clients present on /otlp). Managed by cluster-secrets.
                  existingSecret: task-env
                  persistence:
                    size: 50Gi
                  mediaMounts:
                    - name: task-media
                      mountPath: /mnt/storage/Task
                      hostPath: /mnt/storage/Task
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
                    enabled: false
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
