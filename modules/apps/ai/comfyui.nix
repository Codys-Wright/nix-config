# ComfyUI — node-based image / video model runner: the server + web UI
# (github:utensils/comfyui-nix, CUDA build) as a system service on
# 127.0.0.1:8188, plus a "ComfyUI" app launcher that opens it in its own
# browser window. Not the Electron "ComfyUI Desktop" — the same UI, served.
{ inputs, lib, ... }:
{
  flake-file.inputs.comfyui-nix.url = lib.mkDefault "github:utensils/comfyui-nix";

  fleet.apps._.comfyui = {
    description = "ComfyUI server (CUDA) on 127.0.0.1:8188 + a ComfyUI app launcher";

    nixos = _: {
      imports = [ inputs.comfyui-nix.nixosModules.default ];
      services.comfyui = {
        enable = true;
        gpuSupport = "cuda";
        enableManager = true;
        listenAddress = "127.0.0.1";
        # Runs as the primary user so models can be dropped straight in;
        # data on the Development drive (models are large).
        user = lib.mkDefault "cody";
        group = lib.mkDefault "users";
        createUser = lib.mkDefault false;
        dataDir = lib.mkDefault "/run/media/Development/ComfyUI";
        requiresMounts = lib.mkDefault [ "run-media-Development.mount" ];
      };
    };

    provides.to-users.homeManager =
      { pkgs, ... }:
      let
        open = pkgs.writeShellScript "comfyui-app" ''
          exec ${lib.getExe pkgs.brave} --app=http://127.0.0.1:8188 \
            --user-data-dir="$HOME/.local/share/comfyui-app" "$@"
        '';
      in
      {
        xdg.desktopEntries.comfyui = {
          name = "ComfyUI";
          comment = "Node-based image and video generation (local server on :8188)";
          exec = "${open}";
          icon = "applications-graphics";
          categories = [
            "Graphics"
            "Development"
          ];
        };
      };
  };
}
