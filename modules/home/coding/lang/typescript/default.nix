{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.lang.typescript;
in
{
  options.${namespace}.coding.lang.typescript = with types; {
    enable = mkBoolOpt false "Enable TypeScript web development environment";
  };

  config = mkIf cfg.enable {
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

      # Testing

      # Linting and formatting
      nodePackages.eslint_d
      nodePackages.stylelint

      # Development servers
      nodePackages.live-server

      # Framework CLIs (verified)

      # Utility tools

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
}
