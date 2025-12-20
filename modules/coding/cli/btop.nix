# Btop - system monitor with vim keys
{
  FTS.coding._.cli._.btop = {
    description = "Btop system monitor with vim keys";

    homeManager = {
      programs.btop = {
        enable = true;
        settings = {
          vim_keys = true;
        };
      };
    };
  };
}
