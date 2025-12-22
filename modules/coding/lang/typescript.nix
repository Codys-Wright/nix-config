# TypeScript development environment aspect
{FTS, ...}: {
  FTS.coding._.lang._.typescript = {
    description = "TypeScript and Node.js development environment";

    # Enable nix-ld for running dynamically linked binaries (bun global installs, etc.)
    nixos = {pkgs, ...}: {
      programs.nix-ld = {
        enable = true;
        # Common libraries needed by Node.js/Bun binaries
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          openssl
          curl
          icu
          libuuid
          libsecret
          libGL
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
        ];
      };
    };

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home = {
        packages = with pkgs; [
          # Node.js and package managers
          nodejs_24
          pnpm
          yarn

          # TypeScript core
          typescript
          typescript-language-server
          # Note: ts-node was removed - NodeJS 22.6.0+ has built-in TypeScript support
          tsx

          # Essential development tools
          nodePackages.eslint
          nodePackages.prettier
          nodePackages.webpack-cli

          # Build tools
          esbuild
          turbo

          # Linting and formatting
          nodePackages.eslint_d
          nodePackages.stylelint

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
