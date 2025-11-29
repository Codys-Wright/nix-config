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
  den.aspects = {
    dave = {
      # Include role-based aspects
      includes = [
        den.aspects.developer
        den.aspects.example._.vm
        den.aspects.example._.vm._.gui  # Enable GUI VM support (includes vmVariant automatically)
        den.aspects.minecraft
        den.aspects.desktop
        (den.aspects.terminals { default = "ghostty"; })  # All terminal modules with ghostty as default
        (den.aspects.browsers { default = "brave"; })  # All browser modules with brave as default
        (den.aspects.shell { default = "fish"; })  # All shell modules with fish as default
        (den._.unfree true)  # Allow unfree packages (add more package names as needed)
      ];
    };
  };

}

