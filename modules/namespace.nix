{
  inputs,
  den,
  lib,
  ...
}:
{
  # Create namespaces for aspects
  imports = [
    (inputs.den.namespace "fleet" true) # fleet namespace (exported)
    (inputs.den.namespace "cody" false) # Cody user namespace (not exported)
  ];

  # Enable den angle brackets syntax in modules
  _module.args.__findFile = den.lib.__findFile;

  # Enable home-manager class for all users (required since den v0.14.0)
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
}
