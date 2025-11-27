{ inputs, den, ... }:

{

den.hosts.x86_64-linux = {
    dave = {
      description = "Dave system configuration";
      users.carter = { };
      aspect = "dave";
    };
  };

  # dave host-specific aspect that includes role-based aspects
  den.aspects.dave = {
    # Include role-based aspects
    includes = [
      den.aspects.developer
      den.aspects.example._.vm
      den.aspects.example._.vm._.gui  # Enable GUI VM support (includes vmVariant automatically)
    ];
  };

}

