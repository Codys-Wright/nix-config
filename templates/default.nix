{
  system = {
    description = "A basic NixOS system configuration template using FTS-FLEET namespace";
    path = ./system;
  };
  overlay = {
    description = "A template for creating custom overlays";
    path = ./overlay;
  };
  module = {
    description = "A template for creating NixOS modules";
    path = ./module;
  };
  lib = {
    description = "A template for creating library functions";
    path = ./lib;
  };
} 