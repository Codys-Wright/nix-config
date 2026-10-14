# ComfyUI — node-based image / video model runner: nixpkgs' server + web UI
# (services.comfyui) on 127.0.0.1:8188, plus a "ComfyUI" app launcher that
# opens it in its own browser window.
#
# CUDA: nixpkgs' comfyui builds PyTorch from source (hours with CUDA, and
# cache.nixos.org has no CUDA builds), so torch / torchvision / torchaudio /
# triton are swapped for nixpkgs' prebuilt CUDA wheels (*-bin): a download.
{ lib, ... }:
{
  fleet.apps._.comfyui = {
    description = "ComfyUI server (CUDA, prebuilt PyTorch wheels) on 127.0.0.1:8188 + a ComfyUI app launcher";

    nixos =
      { pkgs, ... }:
      let
        python = pkgs.python3.override {
          packageOverrides = _final: prev: {
            torch = prev.torch-bin;
            torchvision = prev.torchvision-bin;
            torchaudio = prev.torchaudio-bin;
            triton = prev.triton-bin;
          };
        };
      in
      {
        services.comfyui = {
          enable = true;
          package = pkgs.comfyui.override {
            python3 = python;
            withManager = true;
          };
          listen = [ "127.0.0.1" ];
          # Models are large: the Development drive.
          dataDir = lib.mkDefault "/run/media/Development/ComfyUI";
        };
        # Run as the primary user, so models can be dropped straight in.
        systemd.services.comfyui = {
          serviceConfig.User = lib.mkForce "cody";
          serviceConfig.Group = lib.mkForce "users";
          unitConfig.RequiresMountsFor = [ "/run/media/Development" ];
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
