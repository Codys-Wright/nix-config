{ inputs, ... }:
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/nixos-wsl";
    inputs.nixpkgs.follows = "nixpkgs-stable";
    inputs.flake-compat.follows = "";
  };

den.aspects = {
 # aspect for outrider host using github:nix-community/NixOS-WSL
  wsl.nixos = {
    imports = [ inputs.nixos-wsl.nixosModules.default ];
    wsl.enable = true;
  };
};
 
}
