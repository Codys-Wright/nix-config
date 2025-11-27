{ inputs, ... }:

{

den.hosts.x86_64-linux = {
    THEBATTLESHIP = {
      description = "The Main System, ready for everyday battle";
      users.cody = { };
    };
  };

}