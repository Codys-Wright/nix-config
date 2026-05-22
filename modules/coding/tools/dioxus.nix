# Dioxus full-stack dev environment (web/wasm + desktop + mobile-ready).
# Mirrors the toolchain from the dioxus-flake devShell so a system rebuild
# leaves you ready to `dx serve` without entering a nix shell.
#
# The rust toolchain itself (including the wasm32-unknown-unknown target) is
# provided by modules/coding/lang/rust.nix.
{ lib, fleet, ... }:
{
  flake-file.inputs.dioxus-flake.url = lib.mkDefault "github:FastTrackStudios/Dioxus-Flake";
  flake-file.inputs.dioxus-flake.inputs.nixpkgs.follows = "nixpkgs";

  fleet.coding._.tools._.dioxus = {
    description = "Dioxus dev environment: dx CLI, wasm tooling, and desktop (WebKitGTK) deps";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          dioxus-cli
          wasm-bindgen-cli
          binaryen
          tailwindcss_4
          cargo-watch
          bacon
          nodejs_22
          flyctl
        ];

        home.sessionVariables = {
          GDK_BACKEND = "x11";
          WEBKIT_DISABLE_COMPOSITING_MODE = "1";
          WEBKIT_ENABLE_WEBGPU = "0";
          GTK_USE_PORTAL = "0";
        };
      };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          # Desktop (wry / tao) — WebKitGTK stack
          cairo
          cairo.dev
          gtk3
          gtk3.dev
          webkitgtk_4_1
          webkitgtk_4_1.dev
          glib
          glib.dev
          pango
          pango.dev
          atk
          atk.dev
          gdk-pixbuf
          gdk-pixbuf.dev
          libsoup_3
          xdotool
          libappindicator-gtk3

          # Build / wasm native deps
          openssl
          openssl.dev
          pkg-config
          fontconfig
          freetype

          # Graphics
          libGL
          vulkan-loader

          # X11 / Wayland
          libxkbcommon
          wayland

          # WebKit media playback
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
        ];

        environment.variables.PKG_CONFIG_PATH = pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" (
          with pkgs;
          [
            cairo.dev
            gtk3.dev
            webkitgtk_4_1.dev
            glib.dev
            pango.dev
            atk.dev
            gdk-pixbuf.dev
            libsoup_3
            openssl.dev
            fontconfig.dev
            freetype.dev
          ]
        );
      };
  };
}
