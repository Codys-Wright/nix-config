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
  cfg = config.${namespace}.services.selfhost.dashboard.homepage;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.dashboard.homepage = with types; {
    enable = mkBoolOpt false "Enable Homepage dashboard";
    
    misc = mkOpt (listOf (attrsOf (submodule {
      options = {
        description = mkOpt str "" "Description for misc service";
        href = mkOpt str "" "URL for misc service";
        siteMonitor = mkOpt str "" "Site monitor URL";
        icon = mkOpt str "" "Icon for misc service";
      };
    }))) [] "Additional miscellaneous services to show on homepage";
  };

  config = mkIf cfg.enable {
    # Enable Glances for system monitoring widgets
    services.glances.enable = true;
    
    services.homepage-dashboard = {
      enable = true;
      environmentFile = builtins.toFile "homepage.env" "HOMEPAGE_ALLOWED_HOSTS=${selfhostCfg.baseDomain}";
      
      customCSS = ''
        body, html {
          font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
        }
        .font-medium {
          font-weight: 700 !important;
        }
        .font-light {
          font-weight: 500 !important;
        }
        .font-thin {
          font-weight: 400 !important;
        }
        #information-widgets {
          padding-left: 1.5rem;
          padding-right: 1.5rem;
        }
        div#footer {
          display: none;
        }
        .services-group.basis-full.flex-1.px-1.-my-1 {
          padding-bottom: 3rem;
        };
      '';
      
      settings = {
        layout = [
          {
            Glances = {
              header = false;
              style = "row";
              columns = 4;
            };
          }
          {
            Arr = {
              header = true;
              style = "column";
            };
          }
          {
            Downloads = {
              header = true;
              style = "column";
            };
          }
          {
            Media = {
              header = true;
              style = "column";
            };
          }
          {
            Cloud = {
              header = true;
              style = "column";
            };
          }
          {
            Productivity = {
              header = true;
              style = "column";
            };
          }
          {
            Utility = {
              header = true;
              style = "column";
            };
          }
          {
            Networking = {
              header = true;
              style = "column";
            };
          }
          {
            "Smart Home" = {
              header = true;
              style = "column";
            };
          }
        ];
        headerStyle = "clean";
        statusStyle = "dot";
        hideVersion = "true";
      };
      
      services = 
        let
          # Homepage categories that should appear
          homepageCategories = [
            "Arr"
            "Downloads" 
            "Media"
            "Cloud"
            "Productivity"
            "Utility"
            "Networking"
            "Smart Home"
          ];
          
          # Manually traverse known service categories to avoid infinite recursion
          selfhostServices = config.${namespace}.services.selfhost;
          
          # Helper to safely get services from a category
          getServicesFromCategory = categoryPath:
            let
              categoryAttrs = lib.attrByPath categoryPath {} selfhostServices;
            in
            lib.flatten (lib.mapAttrsToList (name: value:
              if lib.isAttrs value && value ? enable && value.enable && value ? homepage && value ? url then
                [{
                  serviceName = name;
                  serviceConfig = value;
                }]
              else []
            ) categoryAttrs);
          
          # Get services from known categories
          allEnabledServices = lib.flatten [
            (getServicesFromCategory ["media"])
            (getServicesFromCategory ["arr"])
            (getServicesFromCategory ["downloads"])
            (getServicesFromCategory ["cloud"])
            (getServicesFromCategory ["productivity"])
            (getServicesFromCategory ["utility"])
            (getServicesFromCategory ["networking"])
            (getServicesFromCategory ["smarthome"])
            (getServicesFromCategory ["dashboard"])
          ];
          
          # Group services by category
          getServicesForCategory = category:
            let
              servicesInCategory = lib.filter (service: 
                service.serviceConfig.homepage.category == category
              ) allEnabledServices;
            in
            map (service: {
              "${service.serviceConfig.homepage.name}" = {
                icon = service.serviceConfig.homepage.icon;
                description = service.serviceConfig.homepage.description;
                href = "https://${service.serviceConfig.url}";
                siteMonitor = "https://${service.serviceConfig.url}";
              };
            }) servicesInCategory;
        in
        # Generate service categories dynamically
        (map (category: {
          "${category}" = getServicesForCategory category;
        }) homepageCategories)
        ++ [
          # Misc services
          { Misc = cfg.misc; }
          
          # Glances monitoring widgets
          {
            Glances = 
              let
                port = toString config.services.glances.port;
              in
              [
                {
                  Info = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "info";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  "CPU Temp" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "sensor:Package id 0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Processes = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "process";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Network = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "network:enp2s0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
              ];
          }
        ];
    };
    
    # Serve homepage on the root domain
    services.caddy.virtualHosts."${selfhostCfg.baseDomain}" = mkIf (selfhostCfg.baseDomain != "") (mkMerge [
      {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
        '';
      }
      (mkIf (selfhostCfg.cloudflare.dnsCredentialsFile != null && selfhostCfg.acme.email != "") {
        useACMEHost = selfhostCfg.baseDomain;
      })
    ]);

  };
} 