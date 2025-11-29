# TypeScript development environment aspect
{
  FTS, ... }:
{
  FTS.typescript = {
    description = "TypeScript and Node.js development environment";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenvNoCC.isDarwin {
        home.packages = with pkgs; [
          # Node.js and package managers
          nodejs_20
          pnpm
          yarn

          # TypeScript core
          typescript
          typescript-language-server
          nodePackages.ts-node
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

          # Development servers
          nodePackages.live-server
        ];

        # Configure pnpm and npm
        home.sessionVariables = {
          PNPM_HOME = "$HOME/.local/share/pnpm";
          NPM_CONFIG_PREFIX = "$HOME/.npm-global";
        };

        home.sessionPath = [
          "$HOME/.local/share/pnpm"
          "$HOME/.npm-global/bin"
        ];
      };
  };
}

