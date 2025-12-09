{
  cody.admin =
    { user, ... }:
    {
      darwin.system.primaryUser = user.userName;
      nixos.users.users.${user.userName} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "uinput"
          "input"
        ];
        initialPassword = "password";
        description = "Cody";
      };
    };
}

