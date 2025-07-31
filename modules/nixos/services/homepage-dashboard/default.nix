{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.homepage-dashboard;
  hostname = "apollo"; # "${networking.hostName}";
in
{
  options.${namespace}.services.homepage-dashboard = with types; {
    enable = mkBoolOpt false "Enable homepage-dashboard";
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 8082;
      settings = {
        background = "https://images.unsplash.com/photo-1730725469217-0832a94d7c2d?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
        color = "neutral";
        theme = "dark";
      };
      allowedHosts = "apollo:8082,0.0.0.0:8082";

      services = [
        {
          "Media Storage" = [
            {
              "Immich" = {
                description = "Self-hosted photo and video backup solution";
                icon = "immich.png";
                href = "http://${hostname}:3001";
              };
            }
            # {
            #   "Jellyfin" = {
            #     description = "Free Software Media System";
            #     icon = "jellyfin.png";
            #     href = "http://${hostname}:8096";
            #   };
            # }
            {
              "Nextcloud" = {
                description = "Sharing solution for files, calendars, contacts and more";
                icon = "nextcloud.png";
                href = "http://${hostname}:8081";
              };
            }
            {
              "Audiobookshelf" = {
                description = "Self-hosted audiobook and podcast server";
                icon = "audiobookshelf.png";
                href = "http://${hostname}:8008";
              };
            }
            {
              "Calibre" = {
                description = "Comprehensive e-book software";
                icon = "calibre.png";
                href = "http://${hostname}:8195";
              };
            }
            {
              "Calibre Web" = {
                description = "Web app for browsing, reading and downloading eBooks stored in a Calibre database";
                icon = "calibre-web.png";
                href = "http://${hostname}:8095";
              };
            }
            {
              "Navidrome" = {
                description = "Navidrome Music Server and Streamer compatible with Subsonic/Airsonic";
                icon = "navidrome.png";
                href = "http://${hostname}:4533";
              };
            }
          ];
        }
        {
          "Other" = [
            {
              "Mealie" = {
                description = "Self hosted recipe manager and meal planner";
                icon = "mealie.png";
                href = "http://${hostname}:8099";
              };
            }
            {
              "Firefly III" = {
                description = "A personal finances manager";
                icon = "firefly.png";
                href = "http://${hostname}:9080";
              };
            }
            {
              "Wanderer" = {
                description = "Self hosted trail database";
                icon = "https://raw.githubusercontent.com/Flomp/wanderer/refs/heads/main/docs/public/favicon.svg";
                href = "http://${hostname}:3000";
              };
            }
            {
              "Ollama" = {
                description = "Ollama web ui";
                icon = "ollama.png";
                href = "http://${hostname}:3050";
              };
            }
            {
              "Referee Assistance Program" = {
                description = "React app to show RAP";
                icon = "https://upload.wikimedia.org/wikipedia/de/5/53/SFV_Logo.svg";
                href = "http://${hostname}:5173";
              };
            }
            {
              "Grafana" = {
                description = "Analytics & monitoring solution for every database.";
                icon = "grafana.png";
                href = "http://${hostname}:3030";
              };
            }
          ];
        }
        {
          "Tools" = [
            {
              "Stirling PDF" = {
                description = "A locally hosted web application that allows you to perform various operations on PDF files";
                icon = "stirling-pdf.png";
                href = "http://${hostname}:8001";
              };
            }
            {
              "Syncthing" = {
                description = "Open Source Continuous File Synchronisation";
                icon = "syncthing.png";
                href = "http://${hostname}:8384";
              };
            }
          ];
        }
      ];
    };
  };
}
