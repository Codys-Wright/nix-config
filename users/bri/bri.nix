{
  fleet,
  den,
  __findFile,
  ...
}:
{
  den.homes.x86_64-linux.bri = {
    userName = "bri";
    aspect = "bri";
  };

  den.aspects.bri = {
    description = "Bri user — local co-op gaming account, launched from Cody's session via ego";

    includes = [
      den.aspects.hm-backup
      <den/primary-user>
      (<den/user-shell> "bash")
      (<fleet.user/password> {
        method = "hashed";
        value = "$6$.E5U9uf5rBti35ez$7x.Rmf/Sfu7tN6g0qMEShgRhi3rxF62P4bJHvqQkJcrRF/fSlwkK6mxtWrM1XAFfref6BIkFrUmnrKr5CzyiJ1";
      })

      # Proton tooling (protonup-rs, protontricks, dotnet 6) in bri's home.
      # System-wide GE-Proton comes from <fleet.gaming/steam> at the host.
      <fleet.gaming/proton>
    ];

    nixos =
      { ... }:
      {
        users.users.bri = {
          isNormalUser = true;
          description = "Bri";
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
