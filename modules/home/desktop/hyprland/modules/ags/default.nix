{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.hyprland.modules.ags;
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  options.${namespace}.desktop.hyprland.modules.ags = with types; {
    enable = mkBoolOpt false "Enable AGS desktop shell";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      sassc
      socat
      imagemagick
      pavucontrol # audio
      wayshot # screen recorder
      wf-recorder # screen recorder
      swappy # screen recorder
      wl-gammactl
      brightnessctl
      gjs
      networkmanagerapplet
      blueman
    ];

    programs.ags = {
      enable = true;
      configDir = ./config;
      extraPackages = with pkgs; [ accountsservice ];
    };
  };
}
