# The two commands the always-on Teley service runs, shared by the Linux
# (home-manager) and macOS (launchd) halves of modules/coding/cli/teley.nix.
#
# `teley-worker` is devenv-fleet's pkgs/teley.nix; `teley-collector` mirrors
# devenv-fleet's telemetry/devenv.nix (otelcol on :4318, forwarding to
# `/r/<room>` with batching), so a dev shell's `devenv up` and this service
# are the same stack and attach to each other. Keep the two config blocks in
# step when that module changes.
{ pkgs, devenvFleet }:
let
  teleyPort = 8787;
  otlpPort = 4318;
  healthPort = 13133;
  session = "\${HOME}/.teley/session.json";

  worker = pkgs.callPackage "${devenvFleet}/pkgs/teley.nix" { };

  config = pkgs.writeText "otelcol.yaml" ''
    extensions:
      health_check: {endpoint: "127.0.0.1:${toString healthPort}"}
    receivers:
      otlp:
        protocols:
          http: {endpoint: "127.0.0.1:${toString otlpPort}"}
    exporters:
      otlp_http/teley:
        traces_endpoint: http://127.0.0.1:${toString teleyPort}/r/@ROOM@
        logs_endpoint: http://127.0.0.1:${toString teleyPort}/r/@ROOM@
        metrics_endpoint: http://127.0.0.1:${toString teleyPort}/r/@ROOM@
        retry_on_failure: {enabled: false}
        sending_queue: {enabled: true, queue_size: 200}
    processors:
      batch: {timeout: 2s, send_batch_size: 4096}
      interval: {interval: 15s}
      tail_sampling:
        decision_wait: 5s
        decision_cache: {sampled_cache_size: 100000}
        policies:
          - {name: errors, type: status_code, status_code: {status_codes: [ERROR]}}
          - {name: slow, type: latency, latency: {threshold_ms: 5}}
    service:
      extensions: [health_check]
      telemetry: {logs: {level: warn}, metrics: {level: none}}
      pipelines:
        traces: {receivers: [otlp], processors: [tail_sampling, batch], exporters: [otlp_http/teley]}
        metrics: {receivers: [otlp], processors: [interval, batch], exporters: [otlp_http/teley]}
        logs: {receivers: [otlp], processors: [batch], exporters: [otlp_http/teley]}
  '';

  collector = pkgs.writeShellApplication {
    name = "teley-collector";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      gnused
    ];
    text = ''
      session="${session}"
      # The room teley-cli uses (same file and shape it writes); never printed.
      if [ ! -s "$session" ]; then
        mkdir -p "$(dirname "$session")"
        umask 077
        jq -n \
          --arg r "$(LC_ALL=C tr -dc 'A-Za-z0-9_-' </dev/urandom | head -c 12)" \
          --arg t "$(LC_ALL=C tr -dc 'A-Za-z0-9_-' </dev/urandom | head -c 24)" \
          '{roomId: $r, receiveToken: $t}' > "$session"
      fi
      room=$(jq -r '.roomId // empty' "$session")
      [ -n "$room" ] || { echo "teley-collector: no roomId in $session" >&2; exit 1; }
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/teley"
      mkdir -p "$state"
      sed "s|@ROOM@|$room|g" ${config} > "$state/otelcol.yaml"
      exec ${pkgs.opentelemetry-collector-contrib}/bin/otelcol-contrib --config "$state/otelcol.yaml"
    '';
  };
in
{
  inherit worker collector teleyPort;
}
