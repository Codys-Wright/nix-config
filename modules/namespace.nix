{ inputs, den, ... }:
{
  # Create an FTS namespace for aspects
  imports = [ (inputs.den.namespace "FTS" true) ];

  # Enable den angle brackets syntax in modules
  _module.args.__findFile = den.lib.__findFile;
}

