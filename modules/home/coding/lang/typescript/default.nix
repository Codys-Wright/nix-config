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
      npm-check-updates

      # TypeScript and development tools
      typescript
      typescript-language-server
      nodePackages.ts-node
      nodePackages.tsx
      nodePackages.tsc-watch
      nodePackages.eslint
      nodePackages.prettier
      nodePackages.vite
      nodePackages.webpack-cli
      nodePackages.create-react-app
      nodePackages.next
      nodePackages.create-next-app

      # Build tools and bundlers
      nodePackages.rollup
      nodePackages.parcel
      nodePackages.esbuild
      nodePackages.turbo

      # Testing frameworks
      nodePackages.jest
      nodePackages.vitest
      nodePackages.playwright
      nodePackages.cypress

      # Linting and formatting
      nodePackages.eslint_d
      nodePackages.stylelint
      nodePackages.markdownlint-cli

      # Development servers and tools
      nodePackages.live-server
      nodePackages.nodemon
      nodePackages.concurrently
      nodePackages.cross-env

      # Framework CLIs
      nodePackages."@angular/cli"
      nodePackages."@vue/cli"
      nodePackages.svelte-language-server

      # Database and API tools
      nodePackages.prisma
      nodePackages.drizzle-kit

      # Deployment and serverless
      nodePackages.vercel
      nodePackages.netlify-cli
      nodePackages.serverless

      # Utility libraries
      nodePackages.lodash
      nodePackages.axios
      nodePackages.uuid

      # Development utilities
      nodePackages.npm-check
      nodePackages.npm-run-all
      nodePackages.rimraf
      nodePackages.cpx
      nodePackages.patch-package

      # Type checking and documentation
      nodePackages.typedoc
      nodePackages.tsdx

      # Monorepo tools
      nodePackages.lerna
      nodePackages.nx

      # Browser automation
      puppeteer

      # Code quality
      nodePackages.husky
      nodePackages.lint-staged
      nodePackages.commitizen
      nodePackages.conventional-changelog-cli

      # Additional useful tools
      nodePackages.degit
      nodePackages.serve
      nodePackages.http-server
      nodePackages.json-server
    ];

    # Configure pnpm
    home.sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };

    home.sessionPath = [
      "$HOME/.local/share/pnpm"
      "$HOME/.npm-global/bin"
    ];

    # Create pnpm configuration
    home.file.".npmrc".text = ''
      prefix=~/.npm-global
      update-notifier=false
      fund=false
      audit=false
    '';

    # Create TypeScript configuration template
    home.file.".config/typescript/tsconfig.json".text = builtins.toJSON {
      compilerOptions = {
        target = "ES2022";
        lib = [
          "ES2022"
          "DOM"
          "DOM.Iterable"
        ];
        module = "ESNext";
        moduleResolution = "node";
        resolveJsonModule = true;
        allowImportingTsExtensions = true;
        allowSyntheticDefaultImports = true;
        esModuleInterop = true;
        forceConsistentCasingInFileNames = true;
        strict = true;
        noUncheckedIndexedAccess = true;
        skipLibCheck = true;
        declaration = true;
        declarationMap = true;
        sourceMap = true;
        outDir = "./dist";
        removeComments = false;
        noEmit = false;
        isolatedModules = true;
        allowJs = true;
        checkJs = false;
        jsx = "react-jsx";
      };
      include = [
        "src/**/*"
        "tests/**/*"
      ];
      exclude = [
        "node_modules"
        "dist"
        "build"
      ];
    };

    # Create ESLint configuration template
    home.file.".config/eslint/eslintrc.json".text = builtins.toJSON {
      env = {
        browser = true;
        es2022 = true;
        node = true;
      };
      extends = [
        "eslint:recommended"
        "@typescript-eslint/recommended"
        "@typescript-eslint/recommended-requiring-type-checking"
      ];
      parser = "@typescript-eslint/parser";
      parserOptions = {
        ecmaVersion = 2022;
        sourceType = "module";
        project = "./tsconfig.json";
      };
      plugins = [ "@typescript-eslint" ];
      rules = {
        "@typescript-eslint/no-unused-vars" = "error";
        "@typescript-eslint/explicit-function-return-type" = "warn";
        "@typescript-eslint/no-explicit-any" = "warn";
        "@typescript-eslint/prefer-const" = "error";
      };
    };

    # Create Prettier configuration
    home.file.".config/prettier/prettierrc.json".text = builtins.toJSON {
      semi = true;
      trailingComma = "es5";
      singleQuote = true;
      printWidth = 100;
      tabWidth = 2;
      useTabs = false;
      bracketSpacing = true;
      arrowParens = "avoid";
    };

    # Create Vite configuration template
    home.file.".config/vite/vite.config.ts".text = ''
      import { defineConfig } from 'vite'
      import { resolve } from 'path'

      export default defineConfig({
        build: {
          lib: {
            entry: resolve(__dirname, 'src/index.ts'),
            name: 'MyLib',
            fileName: 'my-lib'
          }
        },
        resolve: {
          alias: {
            '@': resolve(__dirname, 'src')
          }
        }
      })
    '';

    # Create package.json template for new projects
    home.file.".config/typescript/package.json.template".text = builtins.toJSON {
      name = "my-typescript-project";
      version = "1.0.0";
      description = "";
      main = "dist/index.js";
      type = "module";
      scripts = {
        build = "tsc";
        dev = "tsc --watch";
        start = "node dist/index.js";
        test = "jest";
        lint = "eslint src/**/*.ts";
        format = "prettier --write src/**/*.ts";
        clean = "rimraf dist";
      };
      devDependencies = {
        "@types/node" = "^20.0.0";
        "@typescript-eslint/eslint-plugin" = "^6.0.0";
        "@typescript-eslint/parser" = "^6.0.0";
        "eslint" = "^8.0.0";
        "jest" = "^29.0.0";
        "@types/jest" = "^29.0.0";
        "prettier" = "^3.0.0";
        "rimraf" = "^5.0.0";
        "typescript" = "^5.0.0";
      };
    };
  };
}
