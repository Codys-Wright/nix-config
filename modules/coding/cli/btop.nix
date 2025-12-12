# Btop - system monitor with vim keys
{
  FTS, ... }:
{
  FTS.coding._.cli._.btop = {
    description = "Btop system monitor with vim keys";

    homeManager = { pkgs, lib, ... }: {
      programs.btop = {
        enable = true;
        settings = {
          vim_keys = true;
        };
      };
    };
  };
}

