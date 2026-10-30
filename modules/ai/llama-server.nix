# Local LLMs: llama.cpp's llama-server in router mode, one OpenAI-compatible
# endpoint per host that loads whichever model a request names, downloading
# Hugging Face GGUFs on demand (`llm pull unsloth/gpt-oss-20b-GGUF:Q4_K_M`).
# Clients (Hermes, pi, the built-in web UI) point at
# http://<host>:<port>/v1 and pick a model by its `llm ls` id.
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
      modelsMax = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Models loaded at once; loading another unloads the least recently used";
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

        llm = pkgs.writeShellApplication {
          name = "llm";
          runtimeInputs = [
            pkgs.curl
            pkgs.jq
            pkgs.coreutils
            package
          ];
          text = builtins.readFile ./_llm.sh;
          runtimeEnv.LLM_DEFAULT_URL = "http://127.0.0.1:${toString cfg.port}";
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
          };
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
        };

        networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
          allowedTCPPorts = [ cfg.port ];
        });

        environment.systemPackages = [
          llm
          package
        ];
        # pi's built-in llama.cpp provider (/llama downloads, loads, unloads).
        environment.variables.LLAMA_BASE_URL = "http://127.0.0.1:${toString cfg.port}";
      };
  };
}
