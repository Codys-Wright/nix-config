
{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./nix)

    (inputs.import-tree ./flake)

    (inputs.import-tree ./coding)

    (inputs.import-tree ./config)

    (inputs.import-tree ./desktop)

    (inputs.import-tree ./gaming)

    (inputs.import-tree ./system)

    (inputs.import-tree ./keyboard)

    (inputs.import-tree ./aspects)

    (inputs.import-tree ./hardware)

    (inputs.import-tree ./deployment)
     ];
}
