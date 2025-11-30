{
  # Set default shell to fish for cody user
  cody.default-shell =
    { user, ... }:
    {
      nixos = { pkgs, ... }: {
        # Enable fish shell
        programs.fish.enable = true;
        # Set fish as the default shell for cody
        users.users.${user.userName}.shell = pkgs.fish;
      };
      darwin = { pkgs, ... }: {
        # Enable fish shell on Darwin
        programs.fish.enable = true;
        # Set fish as the default shell for cody
        users.users.${user.userName}.shell = pkgs.fish;
      };
    };
}

