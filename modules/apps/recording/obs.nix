# OBS Studio — screen recording and streaming with NVIDIA hardware acceleration
{
  fleet,
  ...
}:
{
  fleet.apps._.recording._.obs = {
    description = "OBS Studio with Wayland capture, pipewire audio, and NVIDIA encoding";

    nixos =
      { config, ... }:
      {
        # Virtual camera support (v4l2loopback + polkit)
        programs.obs-studio.enableVirtualCamera = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        programs.obs-studio = {
          enable = true;

          # NVIDIA hardware acceleration
          package = pkgs.obs-studio.override {
            cudaSupport = true;
          };

          plugins = with pkgs.obs-studio-plugins; [
            wlrobs # Wayland screen capture (wlroots/niri)
            obs-pipewire-audio-capture # PipeWire audio capture
            obs-gstreamer # GStreamer-based sources/encoders
            obs-vkcapture # Vulkan/OpenGL game capture
            obs-backgroundremoval # AI background removal
          ];
        };
      };
  };
}
