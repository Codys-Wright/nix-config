
{ inputs, ... }:
{
  imports = [ 
    (inputs.import-tree ./nix)
  
    (inputs.import-tree ./flake)

    (inputs.import-tree ./coding)
  
     ];
}