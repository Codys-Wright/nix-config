{ inputs, ... }:

{

den.hosts.x86_64-linux = {
    starcommand = {
      description = "A home-server that facillitates connections with the rest of the fleet";
      users.cody = { };
    };
  };

}