{ inputs, ... }:

{

den.hosts.x86_64-linux = {
    outrider = {
      description = "WSL system that goes where no other system has gone before (Windows)";
      users.cody = { };
      aspect = "wsl";
      intoAttr = "wslConfigurations";
      # custom nixpkgs channel.
      instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
    };
  };

}