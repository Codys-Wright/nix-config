{ inputs, ... }:

{

den.hosts.x86_64-linux = {
    dave = {
      description = "Dave system configuration";
      users.carter = { };
    };
  };

}

