{ inputs, den, ... }:
{
  # Create namespaces for aspects
  imports = [
    (inputs.den.namespace "FTS" true)  # FTS namespace (exported)
    (inputs.den.namespace "deployment" true)  # Deployment namespace (exported)
    (inputs.den.namespace "cody" false)  # Cody user namespace (not exported)
  ];

  # Enable den angle brackets syntax in modules
  _module.args.__findFile = den.lib.__findFile;
}

