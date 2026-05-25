# Brave Browser aspect
{
  fleet.apps._.misc._.nextcloud-client = {
    description = "Brave Browser - Privacy-focused Chromium-based browser";

    # nextcloud-client (the Qt desktop sync client) isn't available on darwin
    # via nixpkgs; skip it there (macOS uses the official .app instead).
    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenv.isLinux {
        home.packages = [ pkgs.nextcloud-client ];
      };
  };
}
