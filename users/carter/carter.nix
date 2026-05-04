{
  fleet,
  den,
  __findFile,
  ...
}:
{
  den.homes.x86_64-linux.carter = {
    userName = "carter";
  };

  den.aspects.carter = {
    description = "Carter user — local co-op gaming account, launched from Cody's session via ego";

    includes = [
      den.aspects.hm-backup
      <den/primary-user>
      (<den/user-shell> "bash")
      (<fleet.user/password> {
        method = "hashed";
        value = "$6$fncYrVMO/9rhDTcj$bL6xaLsi3pv2c4N8FPFjEM8FoHsbL8ZORPq9cyKI8CWrS/UzknCsslUICzCvtAVv3cgQ3MDiDsEsammxQNxOj1";
      })

      # Proton tooling (protonup-rs, protontricks, dotnet 6) in carter's home.
      # System-wide GE-Proton comes from <fleet.gaming/steam> at the host.
      <fleet.gaming/proton>
    ];

    nixos =
      { ... }:
      {
        users.users.carter = {
          isNormalUser = true;
          description = "Carter";
          extraGroups = [
            "networkmanager"
            "audio"
            "video"
            "render"
            "input"
            "gamemode"
            "pipewire"
          ];
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          firefox
          vim
          htop
          git
        ];
      };
  };
}
