# Python development environment aspect
{
  fleet,
  pkgs,
  ...
}:
{
  fleet.coding._.lang._.python = {
    description = "Python development environment with essential tools";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Python interpreter and tools
          python3
          python3Packages.pip
          python3Packages.virtualenv

          # Build tools (required by node-gyp and native modules)
          python3Packages.setuptools

          # Development tools
          python3Packages.black
          python3Packages.pylint
          python3Packages.pytest

          # Language server
          pyright
        ];

        # Ensure python is available in PATH
        home.sessionVariables = {
          PYTHON = "${pkgs.python3}/bin/python3";
        };
      };
  };
}
