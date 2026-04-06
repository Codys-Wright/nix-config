# Dioxus desktop development environment
# Provides native system libraries required to build Dioxus desktop apps on Linux.
# Dioxus desktop uses wry (WebKitGTK2) for the webview backend.
{ fleet, ... }:
{
  fleet.coding._.tools._.dioxus = {
    description = "Dioxus desktop native build dependencies (cairo, WebKitGTK, GTK3, etc.)";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Dioxus CLI
          dioxus-cli
        ];
      };

    nixos =
      { pkgs, ... }:
      {
        # System libraries needed by Dioxus desktop (wry/tao/webkit2gtk)
        environment.systemPackages = with pkgs; [
          # Cairo graphics
          cairo
          cairo.dev

          # GTK3 (tao uses GTK3)
          gtk3
          gtk3.dev

          # WebKitGTK (wry webview backend)
          webkitgtk_4_1
          webkitgtk_4_1.dev

          # GLib / GObject
          glib
          glib.dev

          # Pango text rendering
          pango
          pango.dev

          # ATK accessibility
          atk
          atk.dev

          # GDK PixBuf
          gdk-pixbuf
          gdk-pixbuf.dev

          # libsoup (WebKit HTTP)
          libsoup_3

          # JavaScriptCore (WebKit JS engine)
          # Included transitively via webkitgtk

          # X11 / Wayland display
          xdotool
          libappindicator-gtk3

          # Build tooling already in rust aspect; repeated here for standalone use
          pkg-config
        ];

        # Expose all .pc files so cargo build scripts can find them
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
          ]
        );
      };
  };
}
