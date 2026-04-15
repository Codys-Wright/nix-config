# TypeScript development environment aspect
{ fleet, ... }:
{
  fleet.coding._.lang._.typescript = {
    description = "TypeScript and Node.js development environment";

    # Enable nix-ld for running dynamically linked binaries (bun global installs, etc.)
    nixos =
      { pkgs, lib, ... }:
      {
        # Make nix-ld libraries available to dlopen (e.g. pip pygame's bundled SDL2)
        environment.sessionVariables.LD_LIBRARY_PATH = lib.mkForce "/run/current-system/sw/share/nix-ld/lib";

        programs.nix-ld = {
          enable = true;
          # Common libraries needed by dynamically linked binaries
          libraries = with pkgs; [
            stdenv.cc.cc.lib
            zlib
            openssl
            curl
            icu
            libuuid
            libsecret

            # Graphics / SDL2 / pygame support
            libGL
            SDL2
            SDL2_image
            SDL2_mixer
            SDL2_ttf

            # X11
            xorg.libX11
            xorg.libXcursor
            xorg.libXrandr
            xorg.libXi
            xorg.libXext
            xorg.libXinerama
            xorg.libXScrnSaver

            # Wayland
            wayland
            libxkbcommon

            # Media / codecs
            libpng
            libjpeg
            freetype
            fontconfig
          ];
        };
      };

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home = {
          packages = with pkgs; [
            # Node.js and package managers
            (lib.hiPrio nodejs_24)
            pnpm
            yarn

            # TypeScript core
            typescript
            typescript-language-server
            # Note: ts-node was removed - NodeJS 22.6.0+ has built-in TypeScript support
            tsx

            # Essential development tools
            eslint
            prettier
            webpack-cli

            # Build tools
            esbuild
            turbo

            # Linting and formatting
            eslint_d
            stylelint

            # CSS tooling
            tailwindcss

            bun

            # Development servers
            # Note: live-server was removed - use alternatives like 'serve' or 'http-server'
          ];

          # Configure pnpm and npm
          sessionVariables = {
            PNPM_HOME = "$HOME/.local/share/pnpm";
            NPM_CONFIG_PREFIX = "$HOME/.npm-global";
          };

          sessionPath = [
            "$HOME/.local/share/pnpm"
            "$HOME/.npm-global/bin"
            "$HOME/.bun/bin"
          ];
        };
      };
  };
}
