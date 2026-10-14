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
        # A nixpkgs scoped to ComfyUI whose Python sets use the CUDA 13 wheels
        # (*-bin): comfyui re-overrides python3 internally, so a plain
        # `python3 = …` override is dropped.
        cudaWheels = pkgs.extend (
          final: prev: {
            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (_: pp: {
                torch = pp.torch-bin;
                torchvision = pp.torchvision-bin;
                torchaudio = pp.torchaudio-bin;
                triton = pp.triton-bin;
                # The cu130 wheels need cuda-bindings >= 13 (default set is 12.x).
                cuda-bindings = pp.cuda-bindings.override { cudaPackages = final.cudaPackages_13; };
              })
            ];
          }
        );
      in
      {
        services.comfyui = {
          enable = true;
          package = cudaWheels.comfyui.override { withManager = true; };
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
