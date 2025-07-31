{
    # Snowfall Lib provides a customized `lib` instance with access to your flake's library
    # as well as the libraries available from your flake's inputs.
    lib,
    # An instance of `pkgs` with your overlays and packages applied is also available.
    pkgs,
    # You also have access to your flake's inputs.
    inputs,

    # Additional metadata is provided by Snowfall Lib.
    namespace, # The namespace used for your flake, defaulting to "internal" if not set.
    system, # The system architecture for this host (eg. `x86_64-linux`).
    target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
    format, # A normalized name for the system target (eg. `iso`).
    virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
    systems, # An attribute map of your defined hosts.

    # All other arguments come from the module system.
    config,
    ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.themes.stylix;
in
{
  options.${namespace}.system.themes.stylix = with types; {
    enable = mkBoolOpt false ''
      Whether to enable Stylix theming.
      
      When enabled, this module will:
      - Configure Stylix with a dark theme (Gruvbox)
      - Set up custom fonts (JetBrains Mono, DejaVu, Noto Emoji)
      - Configure cursor theme (Bibata Modern Ice)
      - Apply theming to the entire system
      
      Example:
      ```nix
      FTS-FLEET = {
        system.themes.stylix = enabled;
      };
      ```
    '';
    
    base16Scheme = mkOpt str "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml" ''
      The base16 color scheme to use for theming.
      Defaults to Gruvbox dark medium theme.
    '';
    
    image = mkOpt (either path str) "/home/cody/nix-config/Windows-11-PRO.png" ''
      Path to the wallpaper image.
      Defaults to Windows 11 Pro wallpaper.
    '';
    
    cursor = {
      package = mkOpt package pkgs.bibata-cursors ''
        The cursor package to use.
      '';
      name = mkOpt str "Bibata-Modern-Ice" ''
        The name of the cursor theme.
      '';
      size = mkOpt int 24 ''
        The size of the cursor.
      '';
    };
    
    fonts = {
      monospace = {
        package = mkOpt package pkgs.nerd-fonts.jetbrains-mono ''
          The monospace font package.
        '';
        name = mkOpt str "JetBrainsMono Nerd Font Mono" ''
          The name of the monospace font.
        '';
      };
      sansSerif = {
        package = mkOpt package pkgs.dejavu_fonts ''
          The sans-serif font package.
        '';
        name = mkOpt str "DejaVu Sans" ''
          The name of the sans-serif font.
        '';
      };
      serif = {
        package = mkOpt package pkgs.dejavu_fonts ''
          The serif font package.
        '';
        name = mkOpt str "DejaVu Serif" ''
          The name of the serif font.
        '';
      };
      emoji = {
        package = mkOpt package pkgs.noto-fonts-emoji ''
          The emoji font package.
        '';
        name = mkOpt str "Noto Color Emoji" ''
          The name of the emoji font.
        '';
      };
    };
    
    polarity = mkOpt (enum [ "light" "dark" ]) "dark" ''
      The polarity of the theme (light or dark).
    '';
  };

  config = mkIf cfg.enable {
    # Configure Stylix
    stylix = {
      enable = true;
      base16Scheme = cfg.base16Scheme;
      image = cfg.image;
      
      cursor = {
        package = cfg.cursor.package;
        name = cfg.cursor.name;
        size = cfg.cursor.size;
      };
      
      fonts = {
        monospace = {
          package = cfg.fonts.monospace.package;
          name = cfg.fonts.monospace.name;
        };
        sansSerif = {
          package = cfg.fonts.sansSerif.package;
          name = cfg.fonts.sansSerif.name;
        };
        serif = {
          package = cfg.fonts.serif.package;
          name = cfg.fonts.serif.name;
        };
        emoji = {
          package = cfg.fonts.emoji.package;
          name = cfg.fonts.emoji.name;
        };
      };
      
      polarity = cfg.polarity;
    };
  };
}
