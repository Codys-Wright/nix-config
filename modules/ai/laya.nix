# Local decision models: upstream laya-serve, TypeSafe Jev's API on
# POST http://127.0.0.1:11435/v1/systemone. A state plus typed questions in
# ("which agent?" with its options), each answer with calibrated
# probabilities out; it never generates text. The Paperclip router (STA-631)
# asks it before an LLM agent is woken.
#
# laya-serve (not Ollaya) because it loads `laya-train` fine-tunes directly
# (`extraModels`), and fine-tuning on our own decisions is where Laya's
# accuracy comes from.
#
# GPU when there is room, CPU when there isn't: laya-serve picks one device
# per process, so the start wrapper reads free VRAM and exports LAYA_DEVICE,
# and a timer restarts the service onto the other device when VRAM pressure
# changes (games, ComfyUI, llama-server). Inference stays fp32 on both, so a
# move never shifts the probabilities our thresholds were fitted on.
{
  fleet,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.laya.url = lib.mkDefault "github:NandhaKishorM/laya/v0.4.21";
  flake-file.inputs.laya.inputs.nixpkgs.follows = "nixpkgs";

  # Per-host knobs: den.hosts.<sys>.<host>.settings.ai.laya.*
  fleet.ai._.laya = {
    description = "laya-serve decision models (Jev /v1/systemone) on localhost, GPU when VRAM allows, else CPU";

    settings = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 11435;
        description = "Listen port on 127.0.0.1 (11435 is where the Paperclip router looks)";
      };
      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "english" ];
        description = "Checkpoints preloaded at startup (english = ModernBERT-large, 421M; also multilingual, typed-decisions)";
      };
      extraModels = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = {
          english = "/var/lib/laya-serve/finetunes/paperclip-router";
        };
        description = "Fine-tuned checkpoints by name (a Hub repo or a local dir); a bundled name re-points it";
      };
      threads = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "torch threads on the CPU; leaves the other cores to builds";
      };
      idleUnloadSeconds = lib.mkOption {
        type = lib.types.ints.unsigned;
        default = 600;
        description = "Unload checkpoints after this long idle (frees most of their VRAM/RAM); 0 = never";
      };
      gpuMinFreeMiB = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4096;
        description = "Start on the GPU only with at least this much VRAM free";
      };
      cpuBelowFreeMiB = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1024;
        description = "Running on the GPU, move to the CPU once free VRAM drops below this";
      };
    };

    nixos =
      {
        config,
        host,
        pkgs,
        ...
      }:
      let
        cfg = host.settings.ai.laya;
        gpu = host.hasAspect fleet.hardware._.nvidia;
        nvidia-smi = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
        freeMiB = "${nvidia-smi} --id=0 --query-gpu=memory.free --format=csv,noheader,nounits";
        upstream = (pkgs.callPackage "${inputs.laya}/nix/package.nix" { }).laya-serve;

        # Decides the device once per start and records it for the rebalancer.
        start = pkgs.writeShellScriptBin "laya-serve" ''
          device=cpu
          ${lib.optionalString gpu ''
            free=$(${freeMiB} 2>/dev/null) || free=0
            if [ "''${free:-0}" -ge ${toString cfg.gpuMinFreeMiB} ]; then device=cuda; fi
            echo "laya-serve: ''${free:-0} MiB VRAM free, starting on $device"
          ''}
          echo "$device" > "$STATE_DIRECTORY/device"
          export LAYA_DEVICE=$device
          exec ${upstream}/bin/laya-serve "$@"
        '';
      in
      {
        imports = [ inputs.laya.nixosModules.laya-serve ];

        services.laya-serve = {
          enable = true;
          package = start;
          host = "127.0.0.1";
          inherit (cfg) port models idleUnloadSeconds;
          device = "cpu"; # overridden per start by the wrapper
          cudaAmp = "fp32";
          threads = cfg.threads;
          # Weights at the commits laya's authors reviewed, not the Hub's moving main.
          revision = "reviewed";
          defaultModel = "english";
          logLevel = "warning";
          extraModels = if cfg.extraModels == { } then null else builtins.toJSON cfg.extraModels;
        };

        # On CUDA, ModernBERT's Triton kernels build a small C helper on first
        # use: they need a writable cache (the service has no HOME), a C
        # compiler and the driver's libcuda. The cache sits in the private
        # /tmp because systemd mounts the DynamicUser state dir noexec, so a
        # helper built there can't be loaded; it rebuilds (~0.5 s) per start.
        systemd.services.laya-serve = lib.mkIf gpu {
          path = [ pkgs.stdenv.cc ];
          environment = {
            TRITON_CACHE_DIR = "/tmp/triton";
            TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib";
          };
        };

        systemd.services.laya-serve-rebalance = lib.mkIf gpu {
          description = "Move laya-serve between GPU and CPU as free VRAM changes";
          serviceConfig.Type = "oneshot";
          script = ''
            ${pkgs.systemd}/bin/systemctl is-active -q laya-serve.service || exit 0
            device=$(cat /var/lib/laya-serve/device 2>/dev/null) || exit 0
            free=$(${freeMiB}) || exit 0
            if [ "$device" = cuda ] && [ "$free" -lt ${toString cfg.cpuBelowFreeMiB} ]; then
              echo "$free MiB VRAM free, moving laya-serve to the CPU"
            elif [ "$device" = cpu ] && [ "$free" -ge ${toString cfg.gpuMinFreeMiB} ]; then
              echo "$free MiB VRAM free, moving laya-serve to the GPU"
            else
              exit 0
            fi
            ${pkgs.systemd}/bin/systemctl restart laya-serve.service
          '';
        };
        systemd.timers.laya-serve-rebalance = lib.mkIf gpu {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "5min";
            OnUnitActiveSec = "2min";
          };
        };
      };
  };
}
