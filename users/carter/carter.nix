{
  FTS,
  den,
  __findFile,
  ...
}:
{
  # Darwin (macOS) home configuration
  den.homes.aarch64-darwin.carter = {
    userName = "electric";
    aspect = "carter";
  };

  # NixOS home configuration
  den.homes.x86_64-linux.carter = {
    userName = "carter";
    aspect = "carter";
  };

  # Carter user aspect - includes user-specific configurations
  den.aspects.carter = {
    description = "Carter user configuration";
    includes = [
      # Home-manager backup system
      den.aspects.hm-backup

      FTS.coding
      <FTS.user/admin>
      <FTS.user/autologin>
      (<FTS.user/shell> { default = "fish"; })
    ];
  };
}
