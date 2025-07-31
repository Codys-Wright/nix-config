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
  cfg = config.${namespace}.programs.ags;
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  options.${namespace}.programs.ags = with types; {
    enable = mkBoolOpt false "Enable ags";
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
