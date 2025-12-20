{
  FTS.apps._.browsers._.brave = {
    description = "Brave Browser - Privacy-focused Chromium-based browser";

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.brave];
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [pkgs.brave];
    };
  };
}
