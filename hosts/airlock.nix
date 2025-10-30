{ inputs, ... }:

{

 den.hosts.aarch64-darwin = {
    airlock = {
      description = "An Mac Mini that holds all the proprietary garbage that can't run on linux";
      users.cody = { };
    };
  };

}