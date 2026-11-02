# Local decision models: Ollaya serving Laya behind TypeSafe Jev's API
# (POST http://127.0.0.1:11435/v1/systemone). A state plus typed questions
# in ("which agent?" with its options), each answer with calibrated
# probabilities out; it never generates text. The Paperclip router (STA-631)
# asks it before an LLM agent is woken.
#
# Localhost only, on the CPU so it never contends with the GPU. Ollaya
# never pulls a model on request, so nixpkgs' ollaya-model-loader pulls
# `models` after the daemon starts (into /var/lib/ollaya/models).
{ lib, ... }:
{
  # Per-host knobs: den.hosts.<sys>.<host>.settings.ai.ollaya.*
  fleet.ai._.ollaya = {
    description = "Ollaya decision-model server (Laya, Jev /v1/systemone) on localhost, CPU only";

    settings = {
      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "laya:en" ];
        description = "Models pulled at startup (laya:en is English ModernBERT-large, about 3 GB RSS loaded on the CPU)";
      };
      threads = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "ONNX Runtime threads per loaded model; leaves the other cores to builds";
      };
    };

    nixos =
      { host, ... }:
      let
        cfg = host.settings.ai.ollaya;
      in
      {
        services.ollaya = {
          enable = true;
          host = "127.0.0.1";
          loadModels = cfg.models;
          settings = {
            OLLAYA_DEVICE = "cpu";
            OLLAYA_THREADS = toString cfg.threads;
            # Stay loaded: a cold load takes seconds and the TypeSafe SDK
            # times out after 10 s.
            OLLAYA_KEEP_ALIVE = "-1";
          };
        };
        # `ollaya run` / `ollaya ps` from a shell talk to the daemon.
        environment.variables.OLLAYA_HOST = "127.0.0.1:11435";
      };
  };
}
