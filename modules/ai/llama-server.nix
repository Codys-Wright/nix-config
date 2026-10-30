# Local LLMs: llama.cpp's llama-server in router mode, one OpenAI-compatible
# endpoint per host that loads whichever model a request names, downloading
# Hugging Face GGUFs on demand (`llm pull unsloth/gpt-oss-20b-GGUF:Q4_K_M`).
# Clients (Hermes, pi, the built-in web UI) point at
# http://<host>:<port>/v1 and pick a model by its `llm ls` id.
#
# `models` are named presets (the INI --models-preset): a short id clients
# can rely on, with per-model flags; the first request downloads it.
#
# Every user of the host gets pi wired to it: a `local` provider in
# ~/.pi/agent/models.json listing the presets, and `pi-local` (pi on
# `defaultModel`).
#
# Models live in the service cache (/var/cache/llama-cpp), readable by
# everyone so `llm bench` can run llama-bench on the same files.
{ fleet, lib, ... }:
{
  # Per-host knobs: den.hosts.<sys>.<host>.settings.ai.llama-server.*
  fleet.ai._.llama-server = {
    description = "llama.cpp router server (OpenAI API, on-demand HF model downloads) and the `llm` CLI";

    settings = {
      backend = lib.mkOption {
        type = lib.types.enum [
          "auto"
          "cuda"
          "rocm"
          "vulkan"
          "cpu"
        ];
        default = "auto";
        description = "GPU backend; auto = cuda on hosts with fleet.hardware.nvidia, else vulkan";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8012;
        description = "Listen port (all interfaces; firewall opens it on `interfaces` only)";
      };
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "tailscale0" ];
        description = "Interfaces the firewall opens the port on";
      };
      ctxSize = lib.mkOption {
        type = lib.types.int;
        default = 65536;
        description = "Context per model (Hermes refuses local models below 64K)";
      };
      device = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Vulkan0";
        description = "Only this device (`llama-server --list-devices`); null = all. Hosts with an iGPU pin the discrete card, else layers split onto the iGPU";
      };
      modelsMax = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Models loaded at once; loading another unloads the least recently used";
      };
      models = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.str
              lib.types.int
              lib.types.float
              lib.types.bool
            ]
          )
        );
        default = {
          # OpenAI's recommended sampling; MXFP4 is the native release.
          gpt-oss-20b = {
            hf-repo = "ggml-org/gpt-oss-20b-GGUF:MXFP4";
            temp = 1.0;
            top-p = 1.0;
            top-k = 0;
          };
        };
        description = "Named model presets: llama-server flags per model id (hf-repo or model required)";
      };
      defaultModel = lib.mkOption {
        type = lib.types.str;
        default = "gpt-oss-20b";
        description = "Preset `pi-local` starts pi on";
      };
      idleSleep = lib.mkOption {
        type = lib.types.int;
        default = 900;
        description = "Seconds idle before a model is put to sleep, freeing VRAM (-1 = never)";
      };
    };

    nixos =
      { host, pkgs, ... }:
      let
        cfg = host.settings.ai.llama-server;
        backend =
          if cfg.backend != "auto" then
            cfg.backend
          else if host.hasAspect fleet.hardware._.nvidia then
            "cuda"
          else
            "vulkan";
        package =
          {
            cuda = pkgs.llama-cpp.override { cudaSupport = true; };
            rocm = pkgs.llama-cpp-rocm;
            vulkan = pkgs.llama-cpp-vulkan;
            cpu = pkgs.llama-cpp;
          }
          .${backend};

        presets = pkgs.writeText "llama-models.ini" (
          lib.generators.toINIWithGlobalSection { } {
            globalSection.version = 1;
            # Hide a preset's cached download from the list (one id per model).
            sections = {
              "*".dedup-cache-models = true;
            }
            // cfg.models;
          }
        );

        llm = pkgs.writeShellApplication {
          name = "llm";
          runtimeInputs = [
            pkgs.curl
            pkgs.jq
            pkgs.coreutils
            package
          ];
          text = builtins.readFile ./_llm.sh;
          runtimeEnv = {
            LLM_DEFAULT_URL = "http://127.0.0.1:${toString cfg.port}";
            LLAMA_CACHE = "/var/cache/llama-cpp";
          };
        };
      in
      {
        services.llama-cpp = {
          enable = true;
          inherit package;
          settings = {
            host = "0.0.0.0";
            inherit (cfg) port;
            ctx-size = cfg.ctxSize;
            models-max = cfg.modelsMax;
            sleep-idle-seconds = cfg.idleSleep;
            models-preset = presets;
          }
          // lib.optionalAttrs (cfg.device != null) { inherit (cfg) device; };
        };

        # A fixed user instead of DynamicUser, so the model cache is a plain
        # world-readable directory (llm bench reads it); GPU drivers JIT, so
        # writable+executable memory must be allowed.
        users.users.llama-cpp = {
          isSystemUser = true;
          group = "llama-cpp";
        };
        users.groups.llama-cpp = { };
        systemd.services.llama-cpp.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "llama-cpp";
          Group = "llama-cpp";
          CacheDirectoryMode = "0755";
          MemoryDenyWriteExecute = lib.mkForce false;
          RestartSec = lib.mkForce 5;
          # Mesa's shader cache (Vulkan) defaults to $HOME, which is /var/empty.
          Environment = [ "MESA_SHADER_CACHE_DIR=/var/cache/llama-cpp/mesa" ];
        };

        networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
          allowedTCPPorts = [ cfg.port ];
        });

        environment.systemPackages = [
          llm
          package
          (pkgs.writeShellScriptBin "pi-local" ''
            exec pi --model local/${cfg.defaultModel} "$@"
          '')
        ];
        # pi's built-in llama.cpp provider (/llama downloads, loads, unloads).
        environment.variables.LLAMA_BASE_URL = "http://127.0.0.1:${toString cfg.port}";
      };

    provides.to-users.homeManager =
      { host, ... }:
      let
        cfg = host.settings.ai.llama-server;
        # gpt-oss takes reasoning_effort low/medium/high.
        piModel =
          id:
          {
            inherit id;
            name = "${id} (local llama.cpp)";
            contextWindow = cfg.ctxSize;
            maxTokens = 16384;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          }
          // lib.optionalAttrs (lib.hasPrefix "gpt-oss" id) {
            reasoning = true;
            thinkingLevelMap = {
              minimal = "low";
              low = "low";
              medium = "medium";
              high = "high";
            };
          };
      in
      {
        home.file.".pi/agent/models.json".text = builtins.toJSON {
          providers.local = {
            baseUrl = "http://127.0.0.1:${toString cfg.port}/v1";
            api = "openai-completions";
            apiKey = "none";
            compat = {
              supportsReasoningEffort = true;
              supportsDeveloperRole = false;
              maxTokensField = "max_tokens";
            };
            models = map piModel (lib.attrNames cfg.models);
          };
        };
      };
  };
}
